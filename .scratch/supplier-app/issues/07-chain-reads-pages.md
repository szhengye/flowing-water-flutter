# 07 — 链上读 + Settlements/Wallet 页(03c)

Type: task
Blocked by: 06
Status: resolved (2026-08-08)

## Question

链上余额/交易历史读取,以及 Settlements 页(Settled 对账视图)+ Wallet 页(余额+交易历史+按 settle tx 查关联流水)。(03 拆分的第三块;承接 05/06。)

## Done looks like

- **链上读**:`getBalance`(MATIC 原生)、`balanceOf`(USDT ERC-20)、Etherscan V2 API 交易历史(需 `POLYGONSCAN_API_KEY`)。复用 05 的 `ChainClient` 端口(`Web3ChainClient.getBalance` 已具备 `getBalance`;USDT `balanceOf` 走 `call`)。
- **Settlements 页**:Settled 只读筛选 + 全量同步 + 逐行 tx+logIndex 对账[进阶] + 未匹配重试[进阶]。
- **Wallet 页**:MATIC/USDT 余额 + 交易历史 + 按 settle tx 查关联流水。
- **路由**:`/settlements`、`/wallet`。

## Context

- 上游参考:`web3-api` `admin.routes.ts` `/wallet/balances`(读余额)+ `polygonscan-client.ts`(交易历史)。转账(发 MATIC/USDT)上游无参考实现,是净新增(若做则属 Wallet 页,且需重评 web3dart 版本——见 03 Fog)。
- 依赖:05(事件/Settled 数据)、06(对账回填,供页面)。
- 配置:`AppConfig.polygonUsdtAddress` / `polygonscanApiKey`(已有);网络运行时切换待 Settings 网络门控(Fog)。

## Answer

已实现(07 = 03c),全量 198 测试绿(+21),lib+test analyze 干净。链上读 + Settlements/Wallet
两页落地,路由 `/settlements` `/wallet` 接到真实页(导航 tile 早就在 `nav_items`)。**无 drift schema
变更**(两表列已齐)→ 无 build_runner。

**代码**:
- `lib/core/chain/chain_client.dart` —— `ChainClient` 端口扩 `getBalance`(MATIC 原生,web3dart
  `Web3Client.getBalance`)+ `getTokenBalance`(USDT balanceOf,最小 ERC20 ABI,对齐上游
  `erc20BalanceOfAbi`)。**Rule 7**:ticket 说"getBalance 已具备"—— 实际端口未暴露,本票扩展(底层
  Web3Client 早有)。
- `lib/core/chain/polygon_event_watcher.dart` —— 加 `sync({full, client})`(「全量同步」;对齐上游
  `/sync-chain-status`):full 把 cursor 重置到 `deployBlock-1`(缺省 0,让 `backfillFloor` 回退 window)
  再 `backfillWith`;增量直 `backfillWith`。未 start → 0。
- `lib/core/chain/chain_watcher_service.dart` —— `syncSettlements({full})` 委托 `_watcher`(未运行→0)。
- `lib/core/chain/polygonscan_client.dart`(新)—— Etherscan V2 客户端(dio 可注入)+ `WalletTx` 模型
  (对齐上游 `EvmWalletTx`)+ `toWalletTx`/`parseEtherscanResponse` 纯函数。`fetchMaticTx`(txlist,18)/
  `fetchUsdtTx`(tokentx,6,contractaddress)。chainid=137(Polygon mainnet 常量)。
- `lib/core/db/provider_chain_settlement_dao.dart` —— `watchAll()`(drift watch,createdAt desc)。
- `lib/core/db/provider_log_dao.dart` —— `getBySettleTx(tx)`(`WHERE settle_tx=?` asc,对齐上游
  `getRecordsBySettleTx`)。
- `lib/core/providers.dart` —— `providerLogDaoProvider` + `providerChainSettlementDaoProvider`(跨
  Settlements/Wallet 复用)。
- `lib/shared/widgets/relay_records_sheet.dart`(新)—— 按 settle tx 查关联 provider_log 流水的
  bottom sheet(Settlements 行点击 / Wallet USDT 钻取共用)。
- `lib/features/settlements/settlements_screen.dart`(新)—— Settled 只读列表(stream watchAll +
  tx 筛选)+ 全量同步按钮(按 `chainWatcherStatus` 门禁)+ 行→关联流水 sheet。
- `lib/features/wallet/wallet_screen.dart`(新)—— MATIC/USDT 余额卡 + 交易历史(matic/usdt tab,
  Etherscan)+ USDT 行→关联流水。余额 provider 内部读 identity+config 守卫 unavailable;tx 按配置就绪 UI 门禁。
- `lib/routing/app_router.dart` —— switch 加 `/settlements`/`/wallet`。

**关键决策(Rule 7 surface)**:
1. **"全量同步" = 上游 `/sync-chain-status {mode:"full"}`**(非"刷新视图"):重置 cursor 全量重扫。
   ticket 措辞模糊,以上游 `admin.routes.ts` 定锚(读 521-545 行确认)。
2. **ChainClient 端口扩展**(非"已具备"):`getBalance`/`getTokenBalance` 新加;两个 `_FakeChainClient`
   (`polygon_event_watcher_test` / `chain_watcher_service_test`)同步补实现。
3. **chainid 固定 137**(Polygon mainnet):Amoy(80002)Etherscan 待 Settings 网络门控 ticket(见 Fog)。
4. **[进阶] 延后**:逐行 tx+logIndex 对账(06 采集即自动对账,关联流水 sheet 已展示结果,手动重对账冗余)
   + 未匹配重试(→ 09)。
5. **关联流水 sheet 双入口**:Settlements 行点击 + Wallet USDT 钻取,共用 `getBySettleTx`。

**留尾(毕业 Fog)**:
- 链上读 / Etherscan 真实往返未验(dev 无 Polygon 配置;e2e 需配置 + operator settle,承 05/06 卡点)。
- Amoy testnet Etherscan(chainid 80002)待 Settings 网络切换 ticket。
- MATIC/USDT 转账(发币)上游无参考,净新增(若做需重评 web3dart 版本,见 03 Fog)—— 未做。

**测试**(+21 → 198):polygonscan 解析(方向/金额符号/手续费/状态/空结果)、settlement_dao `watchAll`、
provider_log `getBySettleTx`、watcher `sync` full/增量/无 client、settlements/wallet widget smoke。
Widget 测试隔离渲染(不套 AppShell → 无 CJK 字体坑,见 cjk-font-test-overflow)。

**解除 04 阻塞**(04 `Blocked by: 02, 07`,均 resolved)。
