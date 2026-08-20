# 02 — Polygon 链交互可行性(Dart)

Type: research
Status: resolved

## Question

Dart/Flutter 能否复刻 provider-server 的 Polygon 链交互?

1. 订阅 `Settled` 事件(viem `watchContractEvent` 的等价)——web3dart 是否支持 `eth_subscribe`(logs 的 WS 订阅)?还是只能轮询 `eth_getLogs`?取舍。
2. 读 MATIC 原生余额 + USDT(ERC-20)余额(`eth_call`)。
3. 签名并发送转账交易(钱包页转 MATIC / USDT)。
4. 解码 `Settled` 事件参数 + `logIndex`(同一 tx 多供应商靠 logIndex 区分)。

## Context

- 上游:`../web3-api/packages/provider-server/src/chain/polygon-event-watcher.ts`(`watchContractEvent` + 本地对账)。
- 合约:`web3-api/packages/contracts/contracts/RelayStationPolygon.sol`(Settled 事件 ABI)。
- 环境:Polygon(Amoy 测试网 / 主网)、USDT 6 decimals、RPC=Alchemy(HTTP `writeContract`/`readContract` + WS `watchContractEvent`)。
- 与 01 相关(转账签名)。

## Done looks like

markdown:每项 yes/no + 推荐 Dart 链库(web3dart?)+ 事件订阅方案(WS subscribe vs 轮询的取舍)+ 已知坑。资产链接挂本 ticket。

## Answer

**全部可行 ✅**,web3dart `3.0.3`(publisher `xclud`)原生覆盖。链交互**不新增依赖**——签名 `Credentials` 直接喂已派生的 secp256k1 keypair(承接 [01](01-dart-crypto-feasibility.md)/[10](10-crypto-interop-spike.md))。

| # | 结论 | API |
|---|---|---|
| 1 事件订阅 | ✅ | `events(FilterOptions)` + WS `socketConnector` = 真 `eth_subscribe` 推送;无 socket 时自动降级轮询 |
| 2 读余额 | ✅ | `getBalance`(原生 MATIC)+ `call(...balanceOf...)`(USDT ERC-20 `eth_call`) |
| 3 签名/发转账 | ✅ | `sendTransaction`/`signTransaction`+`sendRawTransaction`,支持 EIP-1559 |
| 4 解码 Settled+logIndex | ✅ | `getLogs`→`FilterEvent`(含 `logIndex`);**需显式 decode**(无 `.decoded` 字段) |

**承重取舍与坑**(完整见资产):
- **事件方案**:镜像上游三层——WS `events()` 实时(主)+ `getLogs()` 按 ~10 块分页回补(Alchemy 上限)+ 游标 + 指数退避重连。全部可复刻。
- **转账是净新增**:上游无参考实现(原 Solana 钱包端点已删,「Ticket 04+ 才移植」)。web3dart 能力齐全,但无 viem 比对代码。
- **解码无 `.decoded`**:显式调 `ContractEvent.decode*(data, topics)`(实现时核实确切方法名);`vendor` indexed 过滤 + `logIndex` 区分同 tx 多供应商,与上游对齐。
- 其他:`eth_getLogs` 块范围上限需自建分页;WS 重连自管;`BigInt` 精度;字段名 `blockNum`;reorg `removed` 标志 v1 对齐上游忽略。
- **配置**:`POLYGON_CONTRACT_ADDRESS`/`POLYGON_USDT_ADDRESS`/`POLYGON_RPC_URL_WS`/`POLYGON_DEPLOY_BLOCK` 等(上游从 env 读)→ 放置归属 [05](05-app-architecture-state.md)/[06](06-local-persistence-choice.md)。

**资产**:[`assets/02-polygon-chain-findings.md`](../assets/02-polygon-chain-findings.md)(逐项 API 细节 + 取舍 + 坑)。

**无新 ticket / 无 fog 毕业**:本结论不使现有 fog 精确化(迁移割接、移动保活仍赖 03/架构);不影响其他 ticket 的 blocking。
