# 08 — 链监听 app 接线(05 留尾)

Type: task
Blocked by: 05
Status: resolved (2026-08-08)

## Question

把 `PolygonEventWatcher`(05)接入 app 生命周期:identity **unlocked + Polygon 配置齐全** → 起 watcher;**locked / none** → 停;**配置缺失** → disabled(不连);并在 AppShell 状态卡暴露可观测状态。

## Answer

已实现,3 服务测试绿,全量 163 测试绿,lib+test analyze 干净。

**代码**:
- `lib/core/chain/chain_watcher_service.dart` —— `ChainWatcherService extends Notifier<ChainWatcherState>`(**镜像 NodeService 范式**):`build()` 同步判定身份门禁 + 配置门禁 → 返回 `stopped`/`disabled`/`running`;`unlocked+配置齐全` → `_start`(建 watcher + `start()`)。`_gen` 守卫防 stale 启动;`ref.onDispose` 释放 watcher。配 `chainClientFactoryProvider`(默认从 `AppConfig` 建 `Web3ChainClient`;**测试可 override 伪实现**)+ `chainWatcherStatusProvider`(UI 便捷派生)。
- `lib/core/chain/polygon_event_watcher.dart`(05)—— 加 `onPhase: ChainWatchPhase{started,reconnecting,stopped}` 相位回调 + `_disposed` 幂等 `dispose()`(跨 provider 重建安全)。
- `lib/shared/widgets/app_shell.dart` —— `_StatusCard` 加「链监听」状态行(watch `chainWatcherStatusProvider`);**watch 即激活服务**:用户进后台(AppShell 渲染)→ 链监听随身份起跑。原「中转站」行加前缀以区分两行。

**关键决策**:
- **配置门禁在 `build()` 同步判定**(不在 `_start`):`_start` 的同步段(首个 await 前)若 `state=disabled` 会被 `build()` 的 `return running` 覆盖(实测踩到)。把门禁上移到 `build()` 让它成为初始状态唯一来源(同 NodeService)。
- **chainClientFactoryProvider 可注入**:镜像 `relayChannelFactoryProvider`,服务测试 override 成 `_FakeChainClient`(零真实 socket)。
- **identity 用 `overrideWith(_Fake.new)`**:riverpod 2.6.1 的 `AsyncNotifierProvider` 无 `overrideWithValue`;用子类覆写 `build()` 返回固定状态。
- **观察者随 app 跑**:AppShell 一渲染,`chainWatcherStatusProvider` 被watch → 服务激活。dev 默认无 Polygon 配置 → `disabled`(不连);配置齐全才真订阅。

**仍未做(留 Fog/后续)**:**未对真实 Polygon RPC 跑通**(无配置/无合约 Settled 测试数据);Settings 页未加链监听行(仅 AppShell 侧栏);端到端待 relay operator 触发 `settle()`。这些不阻塞,06/07 实施时自然验证。

**解阻**:无新阻塞;06(frontier)不受影响。

## Amoy smoke (2026-08-08)

`spikes/chain-smoke/dart-spike/` 真连 Amoy(`POLYGON_RPC_URL`/`CONTRACT_ADDRESS`/`USDT_ADDRESS`/`POLYGONSCAN_API_KEY`),验证 web3dart→Amoy:

| 项 | 结果 |
|---|---|
| 连通 `getBlockNumber` | ✅ latest = 44369050 |
| MATIC `getBalance`(读路径) | ✅ |
| USDT `balanceOf`(ERC-20 读,07 复用) | ✅ |
| Settled ABI 解析 + topic0 签名 | ✅ `0xc276ed00…60de` |
| `getLogs` 分页(page=10) | ✅ 无 free-tier 报错 |
| WS `eth_subscribe` 实时订阅 | ✅ 5s 干净无 onError |

**未验采集**:该合约(`0x08Eb…28A9`)**历史 0 笔 Settled**(Polygonscan 确认)——无人调用过 `settle()`。故 decode 未能上真实事件(仅单测覆盖;ABI 已验解析 + topic0 正确)。**要验端到端采集,需 relay operator 触发 `settle()` 给某 vendor 发一笔 Settled**。

**⚠️ 运营发现**:Alchemy **免费层 `eth_getLogs` 上限 = 10 块/请求**(实测报错原文为证)。watcher 的 `page=10` 正确;但**冷启动 backfill 在 72h window(= 129,600 块)下 ≈ 12,960 个请求**,免费层会极慢/限流。缓解:设 `POLYGON_DEPLOY_BLOCK`(贴近当前)或换 PAYG/dedicated RPC。详见 map Fog。

**已据此接线**:`polygonDeployBlock` 入 `AppConfig`(`POLYGON_DEPLOY_BLOCK` define)→ `ChainWatcherService` → watcher `deployBlock`。部署时设此值即限定 backfill 下限(如 `=latest-100` 则冷 backfill 仅 ~10 请求)。163 测试仍绿,analyze 干净。
