# 03 — 链上结算对账

Type: task
Blocked by: 01
Status: split → 05/06/07(2026-08-08;本票保留为历史 + Version decision)

## Question

监听 Polygon 上 `RelayStationPolygon.Settled` 事件,与本地 `provider_log` 对账(回填 chain_status/settle_tx/log_index),并提供链上余额/交易历史查看。

## Done looks like

- **PolygonEventWatcher**(web3dart `events()` WS 订阅 + `socketConnector` 降级 + getLogs 分页回补,filter `vendor=providerAddress`)+ 指数退避重连。
- **backfill 三层 floor**:`chain_sync_cursor`(scope=`provider_settled`)/ `POLYGON_DEPLOY_BLOCK` / recent window(默认 72h);getLogs 10-block 分页;游标仅全程成功才推进。
- **对账**:Settled → 写 `provider_chain_settlement` → 经 WS `query_relay_records_by_tx_logindex(tx, logIndex)` 回填 `provider_log`(chain_status/settle_tx/log_index);零匹配写 `unmatched_settled_events`。
- **未匹配事件重试**[进阶]。
- **链上读**:`getBalance`(MATIC)、`balanceOf`(USDT)、Etherscan V2 API 交易历史(需 `POLYGONSCAN_API_KEY`)。
- **Settlements 页**:Settled 只读筛选 + 全量同步 + 逐行 tx+logIndex 对账[进阶] + 未匹配重试[进阶]。
- **Wallet 页**:MATIC/USDT 余额 + 交易历史 + 按 settle tx 查关联流水。

## Context

- 依赖 01(WS `query_relay_records_by_tx_logindex`)。
- **合约 ABI**:从 `../web3-api` 拷 `RelayStationPolygon` ABI(`wsUrl()`/`Settled`/`balanceOf`),落 `lib/core/chain/abi/`。
- 链交互可行性见姊妹 `../supplier-portal/issues/02-dart-chain-interaction.md`。
- ⚠️ **web3dart 版本(Fog)**:姊妹 02 基于 **3.0.3** 验证 events/getLogs,但 M0/M1 锁 `^2.7.3`。**实现前先定版本**(读姊妹 02 ticket + `spikes/crypto-interop/dart-spike` 对照 API),统一 pubspec。
- 测试卡点:端到端对账需 relay operator 触发 `settle()`。

## Version decision (2026-08-08) — ⚠️ Fog「web3dart 版本统一」已定

**结论:保持 `web3dart: ^2.7.3`,不升 3.x。** 03 所需全部链 API 在当前锁定的 2.7.3 中**已存在且 API 形态一致**(源码核实,非文档推断):

| API | 2.7.3 位置 | 用途 |
|---|---|---|
| `Web3Client(url, httpClient, {socketConnector})` | `core/client.dart:28` | socketConnector 注入 WS |
| `events(FilterOptions) → Stream<FilterEvent>` | `core/client.dart:522` | 真 `eth_subscribe`(socketConnector 非空)+ 自动降级轮询 |
| `getLogs(FilterOptions) → List<FilterEvent>` | `core/client.dart:280` | 回补分页 |
| `FilterOptions.events({contract, event})` | `core/filters.dart:68` | `topics[0]=event.signature` 过滤 |
| `FilterEvent{removed,logIndex,blockNum,data,topics,...}` | `core/filters.dart:121` | 形态与姊妹 02 findings 一致(`blockNum` 非 `blockNumber`) |
| `getBalance(addr,{atBlock})` | `core/client.dart:198` | MATIC 原生余额 |

姊妹 02(findings 验于 3.0.3 文档)→ 2.7.3 **零改动可移植**。

**为何不升 3.0.3**:实测 `flutter pub get` —— web3dart `^3.0.0` 强制 pointycastle `^4.0.0`,与本仓 `pointycastle: ^3.8.0`(M1 `aes_gcm.dart` AES-256-GCM)冲突;升级级联 AES 加密路径迁移,而 03 的链读/对账 API 在 2.7.3 已具备,**无功能增益**。3.0.3 独有的 Celo type-123 / EIP-1559 prefix fix #169 不在 03 范围(03 不发转账;Wallet 页发送为后续)。

**遗留**:Wallet 页转账若将来确需 EIP-1559 prefix fix,再单独评估 web3dart 3.x + pointycastle 4.x 的 AES 迁移,届时开新 ticket。

**ABI 落地勘误**:ticket 假设「从 `../web3-api` 拷 ABI」—— 实测 web3-api **无签入的编译 ABI JSON**,仅有 `packages/contracts/contracts/RelayStationPolygon.sol`(`event Settled` @L65 / `wsUrl` / `initialize`)。实现时需**派生** ABI(hardhat 编译出 artifacts,或手写最小 ABI:`Settled` event + `wsUrl()` view;USDT `balanceOf` 走 ERC20 标准 ABI)。

---
**进度**:版本门禁已解(本 Fog 从 map 清除);**实现未开始**。PolygonEventWatcher / backfill 三层 floor / 对账(query_relay_records_by_tx_logindex) / 链上读(getBalance+balanceOf+Etherscan) / Settlements+Wallet 页为后续多会话工作。⚠️ **03 Done list 跨 5+ 子系统,体量超单会话**:建议后续会话拆分推进(例:`03a` 事件监听+backfill / `03b` 对账+未匹配 / `03c` 链上读+两页),由实施会话定。
