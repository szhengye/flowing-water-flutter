# 05 — 链上事件监听 + backfill(03a)

Type: task
Blocked by: 01
Status: resolved (2026-08-08)

## Question

监听 Polygon 上 `RelayStationPolygon.Settled` 事件(vendor = 本供应商地址),幂等写入 `provider_chain_settlement`,并按三层 floor backfill 跨重启续点。(03 拆分的第一块;对账在 06,链上读/页面在 07。)

## Done looks like

- **PolygonEventWatcher**(web3dart `events()` WS 订阅 + `socketConnector` + `getLogs` 分页回补,filter `vendor=providerAddress`)+ full-jitter 指数退避重连(对齐 relay ws_client)。
- **backfill 三层 floor**:`chain_sync_cursor`(scope=`provider_settled`)/ `POLYGON_DEPLOY_BLOCK` / recent window(默认 72h);getLogs 10-block 分页;**全程成功才推进游标**。
- **Settled 解码**:web3dart `ContractEvent.decodeResults`(无 `.decoded`,显式解码)+ 客户端 vendor 兜底过滤。
- **幂等采集**:已存在 tx 仅补 `logIndex`,否则插入 `provider_chain_settlement`。

## Answer

已实现,21 测试绿,lib+test analyze 干净。

**代码**:
- `lib/core/chain/abi/relay_station.dart` —— Settled event ABI(从 .sol 手写最小 ABI,web3-api 无签入 JSON)+ `SettledEventArgs` 解码 + `relayStationContract()`。
- `lib/core/chain/backfill_math.dart` —— 纯逻辑 `backfillFloor`(三层 floor)/ `logPages`(分页)/ `fullJitterDelaySeconds`(退避),抽出便于单测。
- `lib/core/chain/chain_client.dart` —— `ChainClient` 端口(隔离 web3dart `Web3Client`,可注入伪实现)+ `Web3ChainClient` 包装 + `polygonSocketConnector`(web_socket_channel→`StreamChannel<String>`)。
- `lib/core/chain/polygon_event_watcher.dart` —— `PolygonEventWatcher`:start/stop/dispose + `events()` 订阅 + `handleSettledEvent`(解码+过滤+幂等)+ `backfillWith`(三层 floor+分页+游标推进)+ full-jitter 重连。
- `lib/core/db/chain_sync_cursor_dao.dart` + `provider_chain_settlement_dao.dart` —— 游标 get/set(insertOrReplace)+ settlement exists/insert/setLogIndex。
- 测试:`test/core/chain/{backfill_math,polygon_event_watcher}_test.dart`(floor 续点语义 / 分页边界 / 退避界 / vendor 过滤 / 幂等去重 / 全程成功才推进 / 中途抛错不推进 / cursor 续点)。

**关键决策**:
- **web3dart 保持 `^2.7.3`**(不升 3.x):03 所需链 API 在 2.7.3 已存在且形态一致(源码核实);升 3.x 级联 pointycastle 4.x 冲突 M1 AES。详见 [03](03-chain-settlement-reconcile.md) 的 Version decision。
- **drift schema 零迁移**:`provider_chain_settlement`/`chain_sync_cursor`/`unmatched_settled_events` 三表已在 M0 的 10 表对齐 schema 中(见 `tables.dart`),05 仅加 DAO。
- **vendor 过滤**:用 `FilterOptions.events`(仅 topic0=Settled 签名 + 合约地址)+ 客户端解码后兜底过滤(避免手编 topic1 padding 的隐蔽 bug,牺牲少量效率换正确性)。
- **重连 full-jitter**(非上游的纯指数):对齐 relay ws_client 的代码库约定(优于上游无 jitter),退避可注入(测试固定值)。

**留尾(毕业 Fog)**:**app 生命周期接线未做** —— watcher 是独立可测模块,但尚未(a)用 Riverpod provider 从 `AppConfig`+identity 构造,(b)identity unlock 时 start / lock 时 stop,(c)Settings 加状态行。这层 glue 依赖应用生命周期/NodeService,毕业成 Fog。

**解除 06 阻塞**(06 的对账建在 05 采集的 `provider_chain_settlement` 上)。
