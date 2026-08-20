# 02 findings — Dart/Flutter 复刻 provider-server 的 Polygon 链交互

> Ticket: [02 · Polygon 链交互可行性](../issues/02-dart-chain-interaction.md) · Type: research
> 一手来源:web3dart v3.0.3 API 文档(pub.dev) + 上游 `web3-api` 实现。结论可独立复核。

## 版本与库

- **web3dart `3.0.3`**(publisher `xclud` / pwa.ir verified;repo `github.com/xclud/web3dart`)。
  - 与 [01](../issues/01-dart-crypto-feasibility.md) / [10](../issues/10-crypto-interop-spike.md) 锁定的库栈同一生态(`eth_sig_util` 同 publisher)。**链交互不需要再加新依赖**——签名用的 `Credentials` 由已派生的 secp256k1 keypair 直接喂 `EthPrivateKey.fromHex(...)`。
- `Web3Client(url, httpClient, {socketConnector})`:HTTP 走 `url`+`httpClient`(余额/调用/发交易),WebSocket 走可选 `socketConnector`(仅事件流)。

## 结论一览

| # | 子问题 | 可行? | web3dart API |
|---|---|---|---|
| 1 | 订阅 `Settled` 事件(`watchContractEvent` 等价) | **✅** | `events(FilterOptions)` + WS `socketConnector`;无 socket 时自动降级轮询 |
| 2 | 读 MATIC 原生余额 + USDT(ERC-20)余额 | **✅** | `getBalance` + `call(... balanceOf ...)` |
| 3 | 签名并发送转账(MATIC / USDT) | **✅**(但上游无参考实现) | `sendTransaction` / `signTransaction` + `sendRawTransaction`(支持 EIP-1559) |
| 4 | 解码 `Settled` 事件参数 + `logIndex` | **✅** | `getLogs(FilterOptions)` → `FilterEvent`;**需显式 decode**(无 `.decoded` 字段) |

---

## 1 · 订阅 `Settled` 事件

**web3dart 不暴露裸 `eth_subscribe` 方法**,但提供等价的高层流:`Web3Client.events(FilterOptions) → Stream<FilterEvent>`。机制由构造器可选参数 `socketConnector` 决定:

- **传了 `socketConnector`(WebSocket)**:web3dart 用该 `StreamChannel`「发事件请求并解析响应」= **真正的 `eth_subscribe` 推送**。
- **不传**:文档原文——"a polling implementation for events will be used",自动降级为轮询。
- 另有 `addedBlocks() → Stream<String>`(新块)、`pendingTransactions()`。

**取舍 / 推荐方案**(镜像上游 `polygon-event-watcher.ts` 的三层设计):

| 路径 | 用途 | web3dart | 说明 |
|---|---|---|---|
| WS `events()` | 实时推送(主) | `socketConnector` | 低延迟;桌面 always-on 节点用这条 |
| `getLogs()` 分页 | 启动/断线回补 | `getLogs(FilterOptions)` | 上游按 10 块一页(Alchemy 免费层 ~10 块上限),游标推进 |
| (可选)轮询降级 | 移动前台尽力而为 | `events()` 无 socket | WS 不稳时更健壮;移动后台保活策略见 Fog |

**上游参考**:`polygon-event-watcher.ts` `start()` 用 viem `watchContractEvent`(`webSocket` transport,按 indexed `vendor` 过滤)+ `backfill()` 用 `getLogs` 按 10 块分页 + `chain_sync_cursor` + 指数退避重连(1s→60s 封顶)。**全部可在 Dart 复刻。**

---

## 2 · 读余额

| 余额 | web3dart | 上游(`admin.routes.ts` `/wallet/balances`) |
|---|---|---|
| MATIC 原生 | `getBalance(address, {atBlock}) → EtherAmount` | viem `getBalance` = `eth_getBalance` |
| USDT(ERC-20) | `call(contract: usdt, function: balanceOf, params: [address])` | viem `readContract` `balanceOf` = `eth_call` |

- `USDT = 6 decimals`、`MATIC = 18 decimals`。金额一律 `BigInt`,不要碰 `int`/`double`。
- 平凡支持,无坑。

---

## 3 · 签名并发送转账

**web3dart 明确支持「创建、签名并发送以太坊交易」。**

- `sendTransaction(Credentials, Transaction, {chainId, fetchChainIdFromNetworkId})`——签 + 广播。
- `signTransaction(...)` → `sendRawTransaction(...)`——只签再广播(可离线)。
- EIP-1559 全支持:`estimateGas(... {maxPriorityFeePerGas, maxFeePerGas})`、`Transaction` 支持 type-2 字段。Polygon 走 1559。
- MATIC 原生转账:`Transaction(to, value: EtherAmount)`。
- USDT(ERC-20)转账:`Transaction(to: usdtContract, data: transferFn.encodeCall([to, amount]))`——用 `DeployedContract` + `ContractFunction('transfer')` 编码 calldata。
- 配套:`getTransactionCount`(nonce)、`getChainId`、`getGasPrice`/`getFeeHistory` 都在。

**⚠ 关键:上游目前无转账参考实现。** `admin.routes.ts:870-881` 注释明确——原 Solana `/admin/wallet/*` 转账端点在切 SIWE 时已删,「Ticket 04+ 才移植钱包 UI」。所以**转账对 Flutter 是净新增**(上游只有读余额 + Etherscan 交易历史)。web3dart 能力齐全,但无 viem 参考代码可比对。

---

## 4 · 解码 `Settled` 事件参数 + `logIndex`

**`Settled` 事件 ABI**(`RelayStationPolygon.sol`,ADR-0002 D5):

```solidity
event Settled(
    address indexed vendor,
    uint32 successCount,
    uint256 amount,
    uint32 notSuccessCount,
    uint256 notSuccessAmount,
    uint256 timestamp
);
```

**web3dart `FilterEvent` 字段**:`address`、`transactionHash`、`blockNum`(⚠ 名字是 `blockNum` 非 `blockNumber`)、`logIndex`(int?)、`data`(hex)、`topics`(List<String?>)、`transactionIndex`、`blockHash`、`removed`(reorg 标志)。

**⚠ 解码没有 `.decoded` 字段**——`FilterEvent` 只存原始 hex `data`/`topics`。要显式解码:
- `FilterOptions` 有命名构造器 `.events(contract: DeployedContract, event: ContractEvent)` 用于按事件签名(topic0)过滤 + 绑定事件定义;
- 但把 `data`+`topics` 翻成 `vendor/successCount/amount/...` 类型值,要调 `ContractEvent` 的 decode 方法(在事件定义上标记 `vendor` 为 indexed)。
- **实现时需先确认 `ContractEvent.decode*(...)` 的确切方法名**(v3.0.3 API 细节,本文未逐一核实)。

**同 tx 多供应商区分**(本 ticket 要点):按 **indexed `vendor` = 自己的收款地址**过滤(`topics[1]`,地址补齐 32 字节)+ 用 `logIndex` 在同一 tx 内进一步定位。与上游 `handleSettledEvent(... logIndex)` + `(tx, logIndex)` 反查 relay `relay_log` 完全一致。

---

## 已知坑(汇总)

1. **`eth_getLogs` 块范围上限**:Alchemy 免费层 ~10 块。必须自行分页(上游按 10 块);web3dart `getLogs` 只接受 `fromBlock`/`toBlock`,分页逻辑要自己写。
2. **WS 重连是你的责任**:`socketConnector` 是你提供的 `StreamChannel`;断线/指数退避要自己包(上游 1s→60s)。web3dart 不替你重连。
3. **WS RPC URL 独立配置**:Alchemy/Infura 的 WS 是单独 `wss://` URL。app 要配 `POLYGON_RPC_URL_WS`(HTTP 方法走 `url`,`events()` 走 socket)。
4. **`BigInt` 精度**:uint256/金额一律 `BigInt`;USDT 6 位、MATIC 18 位。
5. **无 `.decoded` 自动解码**:见 Q4,需显式调 `ContractEvent` decode。
6. **reorg 处理**:`FilterEvent.removed` 标志可用,但上游明确「provider-only,不做 revert/reorg 检测」(`polygon-event-watcher.ts` backfill 注释)。**v1 对齐上游:忽略 reorg**,作为已知限制记录。
7. **轮询降级时,默认轮询间隔可能偏粗**——always-on 桌面节点应显式用 WS,不依赖 null-socket 轮询。

## 链上配置(app 需持有的常量,上游从 env 读)

- `POLYGON_CONTRACT_ADDRESS`(RelayStationPolygon)、`POLYGON_USDT_ADDRESS`、`POLYGON_RPC_URL_WS`、`POLYGON_DEPLOY_BLOCK`(回补下限,可选)、`POLYGON_RECENT_WINDOW_HOURS`(默认 72)。
- 链环境:Polygon(Amoy 测试网 / 主网)。链 id 由 `getChainId` 现取。

## 跨链接 / 毕业去向

- **依赖 [01](../issues/01-dart-crypto-feasibility.md) / [10](../issues/10-crypto-interop-scope)**:库栈 + keypair;链交互**不新增**依赖。
- **真握手联调**:链事件/转账不在本 ticket 范围,真实 Polygon RPC 联调待相关 task。
- **配置与状态归属**:链上常量 + 游标持久化的放置 → 属 [05 应用架构与状态](../issues/05-app-architecture-state.md)(cursor 表)/ [06 本地持久化选型](../issues/06-local-persistence-choice.md)。
- **移动端链监听策略**:WS 常驻 vs 轮询降级的具体取舍 → 属 Fog「移动端后台保活」(待 05 定)。
- **Etherscan 交易历史**:钱包 tab 的 MATIC/USDT 交易历史走 Etherscan V2(`polygonscan-client.ts`),与 Settled 监听无关——是否移植到 Dart 直连,属 [07 功能对齐范围](../issues/07-feature-parity-scope.md)。
