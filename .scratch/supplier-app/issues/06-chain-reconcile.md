# 06 — 链上结算对账(03b)

Type: task
Blocked by: 05
Status: resolved (2026-08-08)

## Question

把 `provider_chain_settlement` 里的 Settled 事件,经 WS `query_relay_records_by_tx_logindex(tx, logIndex)` 回填 `provider_log`(`chain_status`/`settle_tx`/`log_index`);零匹配写 `unmatched_settled_events`;未匹配重试[进阶]。(03 拆分的第二块;承接 05 的采集层。)

## Done looks like

- **settle-event-syncer**:拿到 Settled(tx+logIndex)→ WS `query_relay_records_by_tx_logindex` → 回填 `provider_log`(对齐上游 `settle-event-syncer.ts`,强化 retry 5×2s 兜底)。
- **watcher 接线**:扩展 `PolygonEventWatcher.handleSettledEvent`(05 仅采集)—— 采集后调 syncer;wsClient 缺失/零匹配时写 `unmatched_settled_events`(对齐上游:宁可漏记不误记,不做 ±时间窗 fallback)。
- **未匹配事件重试**[进阶]:`unmatched_settled_events` 的 operator retry 路径。
- **依赖**:01 的 WS `query_relay_records_by_tx_logindex` 消息(relay 层 `messages.dart`,已 resolved)+ 05 的 `provider_chain_settlement`。

## Context

- 上游参考:`web3-api/packages/provider-server/src/chain/settle-event-syncer.ts` + `polygon-event-watcher.ts` 的 `handleSettledEvent` 对账段。
- 配置:`POLYGON_CONTRACT_ADDRESS`、provider address(身份)、WS client(NodeService inbound)。
- web3dart 版本见 [03](03-chain-settlement-reconcile.md) Version decision(保持 2.7.3)。
- 测试卡点:端到端对账需 relay operator 触发 `settle()`。

## Answer

已实现(core),177 测试绿,lib+test analyze 干净。对齐上游 `settle-event-syncer.ts` +
`polygon-event-watcher.ts` 的 `handleSettledEvent` 对账段。

**代码**:
- `lib/core/relay/messages.dart` —— 新增 `query_relay_records_by_tx_logindex`(出站 envelope,
  payload `{requestId, tx, logindex}` 小写)+ `query_response`(入站,payload `{requestId, ok, data?, error?}`,
  data 拆平数组或 `{records:[]}`)。按 requestId 请求/响应关联。现有 `query_settlement`(tx 单键)是**不同**消息,未动。
- `lib/core/relay/ws_client.dart` —— `RelayQueryClient` 端口(abstract)+ `WsClient implements`:
  `_queries` requestId→Completer map、`_onMessage` 拦截 `QueryResponse` 不转发上层、
  `queryRelayRecordsByTxLogindex()`(`q_{ts}_{rand8}`、10s 超时、ok=false/未连接/超时抛 `RelayQueryException`)、
  断连/stop `_failPendingQueries`(触发上层 syncer 重试)。
- `lib/core/chain/settle_event_syncer.dart`(新)—— `SettleEventSyncer.sync`:5×2s 重试 WS 反查
  (网络错或空响应都重试,可注入 sleep/maxRetry/retryDelay);命中 → 强制 `chain_status=on_chain_settled`
  (bi-state,relay 3-state 不穿透)+ settle_tx + log_index 回填 provider_log;零匹配/重试耗尽/relay 未连接 →
  写 unmatched_settled_events;**无 ±时间窗**。返回 `SyncResult`。
- `lib/core/db/provider_log_dao.dart` —— `updateChainStatus(requestId, chainStatus, settleTx, logIndex)`,
  WHERE chain_status IN 三态(on_chain_settled 终态幂等)。对齐 relay-records.ts。
- `lib/core/db/unmatched_settled_event_dao.dart`(新)—— `insert`(事务内 select-then-insert,幂等 PK=(tx,logIndex))。
  recordRetry/remove/list/count 留 09。
- `lib/core/chain/polygon_event_watcher.dart` —— 加可选 `syncer`;`handleSettledEvent` 采集后
  `unawaited(syncer.sync(...))`(对齐同文件 backfill 的 fire-and-forget 约定);logIndex null 跳过。
- `lib/core/relay/node_service.dart` —— 暴露 `relayQueryClient` getter(WsClient is-a RelayQueryClient)。
- `lib/core/chain/chain_watcher_service.dart` —— 构造 `SettleEventSyncer`(relayQueryClient supplier 实时
  `ref.read(nodeServiceProvider.notifier).relayQueryClient` + 两 DAO)注入 watcher。
- `lib/core/db/{tables,database}.dart` —— provider_log 加 `logIndex` nullable 列;schemaVersion 1→2 +
  onUpgrade addColumn;`database.g.dart` build_runner 重生成。

**关键决策(Rule 7 surface)**:
1. **查询消息名**:ticket 说依赖"01 的 `query_relay_records_by_tx_logindex`(已 resolved)",但 01 实际只定了
   `query_settlement`(tx 单键、无 requestId,不同消息)。本票新增 `query_relay_records_by_tx_logindex` +
   `query_response`(requestId 关联),按上游 messages.ts 定锚;ticket 措辞不准已修正。
2. **provider_log log_index 列**:上游 syncer 第105行写 log_index,但上游 provider_log 建表**无此列**
   (只在 provider_chain_settlement / unmatched)→ 上游潜伏 bug(链上 0 Settled 未触发)。决策(用户):
   **新增 log_index 列**(drift v2 迁移,忠实 syncer 意图 + ticket 措辞),打破 tables.dart 的"1:1 对齐上游
   schema"声明(上游缺这列)。已标注,待上游补列后回归对齐。
3. **web3dart 保持 `^2.7.3`**(承 03 Version decision;06 不涉链 API)。

**留尾**:
- **operator unmatched retry-all[进阶]→ 新票 09**(blocked by 06):unmatched 列表 / 手动重试
  (`/provider-records/sync-by-tx-logindex` + `/unmatched-settled-events/retry-all`,对齐 admin.routes)。
- 02 进阶(sync/反拉)仍 Fog(依赖 query_model_params,非本票)。
- e2e 对账需 relay operator 触发 `settle()`(承 05 测试卡点)。

**测试**(+14 → 177):`settle_event_syncer_test`(命中 / 强制 on_chain_settled / 零匹配→unmatched /
未连接→unmatched / retry / 幂等 / 不误记)、`messages_test`(query 型 codec 5)、`polygon_event_watcher_test`(syncer 接线 pump + 无 syncer 仅采集)。

**解除 07 阻塞**(07 链上读/页面建在 06 对账结果上)。
