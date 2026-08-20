# 09 — unmatched operator 手动重试(06 进阶)

Type: task
Blocked by: 06
Status: resolved (2026-08-09)

## Question

`unmatched_settled_events` 里的 Settled 事件(06 反查 0 匹配 / 失败耗尽重试后落地),供
operator 手动重试:逐个重调 `SettleEventSyncer.sync` + retry-all;匹配则 remove,仍 0 匹配则
recordRetry。对齐上游 `admin.routes.ts`。06 把它标为[进阶]毕业成本票(core 已做 insert 落地)。

## Done looks like

- **UnmatchedSettledEventDao 补全**:`recordRetry(tx, logIndex)` / `remove` / `list` / `count`(06 仅 insert)。
- **重试入口**(UI Settings 新区 or 端点):列 unmatched → operator 触发重试 → 复用 `SettleEventSyncer.sync`;
  `matched > 0` → remove;仍 0 → recordRetry(更新 retry_count / last_retry_at)。
- **waitForConnected**:重试前确保 relay WS 已连(上游 20s 超时),未连则提示(不盲重试)。

## Context

- 上游参考:`web3-api/packages/provider-server/src/admin.routes.ts` 第 644-696(retry-all)+ 571-626(sync-by-tx-logindex 单笔)。
- 复用 06 的 `SettleEventSyncer.sync`(同一对账原语,watcher 与 operator 共用)。
- web3dart 版本见 [03](03-chain-settlement-reconcile.md)(保持 2.7.3)。

## Answer

已实现 —— operator 手动重试闭环落地,对齐上游 `admin.routes.ts` 的
`GET /unmatched-settled-events` + `POST /unmatched-settled-events/retry-all`。无 HTTP 端点
(桌面 app),入口为 Settings 新区。

**改动:**
- **`UnmatchedSettledEventDao` 补全** —— `list`(detectedAt 倒序)/ `watchAll`(drift watch,UI
  反应式)/ `count` / `remove(tx,logIndex)` / `recordRetry(tx,logIndex)`(事务内 read-modify-write:
  retryCount+1、lastRetryAt=now 秒;行不存在 no-op)。06 仅 `insert` 的缺口补齐。**零 drift schema 变更**
  (`retryCount`/`lastRetryAt` 列 06 已声明)。
- **新 `lib/core/chain/unmatched_retry_service.dart`** —— `UnmatchedRetryService.retryAll()`:① `waitForConnected`
  轮询 `relayQueryClient()` supplier(对齐上游 `waitForConnected(20000)`;超时 20s → `RetrySummary.notConnected`,
  **不动 DAO**、不盲重试);② `list` unmatched;③ 内部按需构造 `SettleEventSyncer`(**同构**
  `ChainWatcherService._start`:同 supplier + 同 DAO;operator 与 watcher 共用同一对账原语);④ 逐条从行重建
  `SettledEventArgs`(字段对齐上游 retry-all 行 672-678)→ `sync`:命中→`remove`,仍 0 匹配→`recordRetry`。
  全协作者构造注入(伪 client supplier + 内存库 + no-op sleep/Duration.zero retryDelay),无 Riverpod 即可单测。
- **Riverpod 接线**(`lib/core/providers.dart`)—— `unmatchedSettledEventDaoProvider` + `unmatchedRetryServiceProvider`
  (supplier 实时取 `nodeServiceProvider.notifier.relayQueryClient`,与 watcher 同源)。
- **Settings 新区**(`lib/features/settings/settings_screen.dart`)—— `_UnmatchedEventsSection`:count 徽标 +
  unmatched 列表(tx 截断 + #logIndex + 重试次数 + USDT[6-dec 格式化])+ `FilledButton.icon`「重试全部」
  (门禁 `nodeStatusProvider==connected`,未连禁用且 label 提示「需连接」;snackbar 汇总:匹配/仍未匹配/未连接跳过)。

**关键决策:**
- `waitForConnected` 轮询 supplier 而非新增 `WsClient.waitForConnected`(本仓传输层无此方法;supplier 是 syncer
  的单一真源,轮询它即等价于上游等 WS 连通)。超时整体跳过(对齐上游 502 早退),**绝不盲重试/误删**。
- operator 与 watcher 各自构造 `SettleEventSyncer`(复用类/原语,非共享实例),与上游 `syncSettledEventToProviderLog`
  被 watcher + admin 路由分别调用同构。不引入跨服务共享状态。
- 仅 retry-all(对齐 ticket 与上游);逐笔重试未做(Rule 2,非 ticket 要求)。

**验证:** `flutter analyze` 干净(lib+test 零 issue;56 个 info 全在 `spikes/` 预存噪声);全量 **217 测试绿**
(新增 8:DAO 5[list/count/insert 幂等/recordRetry 累加·no-op/remove] + service 3[命中→remove+回填 /
relay 超时未连→notConnected 不动 DAO / 空汇总])。e2e 真实往返承 05/06/07 同一卡点(dev 无 Polygon 配置 →
无真实 unmatched 数据)。

**留尾:** 真实 operator-settle 触发产生 unmatched 后的端到端验证,待 Polygon 配置就绪(承 05/06/07 卡点)。

