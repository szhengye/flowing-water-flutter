# 04 — Dashboard / Records + 收尾

Type: task
Blocked by: 02, 07
Status: Dashboard/Records resolved; 收尾 split → 10/11; e2e → Fog (2026-08-09)

## Question

全功能联调,达到与 Node provider-server 行为对齐:Dashboard 看板 + Records 流水 + 系统托盘驻留 + 错误友好/可观测骨架。

## Done looks like

- **Dashboard**:LLM 看板(周期 24h/7d/30d/lifetime:调用/完成率/收益/厂商汇总/模型明细/失败率告警[进阶])+ 链上看板(接 03)+ **节点健康面板**(接 01 状态机 + 低余额告警)+ 顶部 4 KPI 卡 + 绿「Connected · Xms」pill(接 01)。
- **Records 页**:`provider_log` 只读筛选(status / chain_status)。
- **系统托盘驻留**:关窗最小化到托盘,单进程 keep-alive(姊妹 05)。
- **friendlyError**(借 listening-king `error_utils` 模式)+ 本地日志骨架 + 国际化骨架。
- **全功能联调 + 行为对齐**:WS 协议兼容 / crypto 互通 / 结算对账一致 → 割接验证 Fog 收敛(同供应商身份不两端并存)。

## Context

- 依赖 02(provider_log 数据)+ 03(链上看板数据)。
- 视觉参照 M0 设计 token + 姊妹 `../supplier-portal/issues/08-visual-direction-app-shell.md`。
- 节点健康面板定义见姊妹 `../supplier-portal/issues/07-feature-parity-scope.md`。

## Answer

04 是聚合收尾票(5 块),大于单会话容量 —— 本会话用户选定 **Dashboard + Records** 切片实现;其余块(tray / 错误友好 / i18n / e2e)毕业为新票 10/11 + Fog。两个 M5 占位页(`/`、`/records`)落地为真实视图。全量 **209 测试绿(+11)**,lib+test analyze 干净,无 drift schema 变更 → 无 build_runner。

**代码**:
- `lib/core/db/provider_log_dao.dart` —— 加 `watchRecords({processingStatus, chainStatus})`(Records 双维度筛选,drift watch 反应式,createdAt 倒序)+ `watchRecordsSince(sinceEpochSec)`(Dashboard 周期内流水)+ `LlmMetrics`/`ModelBreakdown` 模型 + 纯函数 `computeLlmMetrics(rows)`(计费额/用量只计 `completed`;调用数含全部 → 完成率 = completed/total)。
- `lib/core/relay/ws_client.dart` —— 心跳 RTT:发心跳记 `_heartbeatSentMs`、收回包按 `now - sent` 算往返,暴露 `Stream<int?> latency`;断连/停止清零(null)。`node_service.dart` 转发到 `latencyStream`;新 `nodeLatencyProvider`(StreamProvider)。
- `lib/core/providers.dart` —— `DashboardPeriod`(24h/7d/30d/累计,`since()`)+ `dashboardPeriodProvider`/`dashboardMetricsProvider`/`recordsListProvider`+两筛选 StateProvider/`chainSettlementSummaryProvider`(累计笔数+应收 USDT)。
- `lib/features/dashboard/dashboard_screen.dart`(新)—— 4 KPI(总调用/完成率/计费额 nUSD/平均延迟)+ 节点健康卡(中转站/链监听/延迟/地址)+ 链上汇总卡 + 模型明细(按计费额倒序,前 8)+ 周期 PopupMenu。
- `lib/features/records/records_screen.dart`(新)—— 处理状态/链态双下拉筛选 + provider_log 只读列表(模型/状态徽章/入出 token/计费/延迟/时间/失败原因)。
- `lib/shared/widgets/status_visuals.dart`(新)—— `nodeStatusVisual`/`chainWatcherStatusVisual` 共享映射(抽出 app_shell 与 Dashboard 的 6 态重复)。
- `lib/shared/widgets/app_shell.dart` —— `_TopBar` → ConsumerWidget:接 `nodeStatusProvider`(真色/标签)+ `nodeLatencyProvider`(已连接附 `· Xms`,首心跳回包前/未连 `--ms`/`—`);`_StatusCard` 改用共享 visuals(删本地 `_statusVisual`/`_chainVisual`)。
- `lib/routing/app_router.dart` —— `/`→Dashboard、`/records`→Records。

**关键决策(Rule 7 surface)**:
1. **「Xms」= 心跳 RTT**(非杜撰):WsClient 原先丢弃心跳回包,本票加 RTT(发-收时刻差)。心跳 15s → 延迟 15s 更新一次;首回包前/未连显示 `--ms`/`—`。
2. **Dashboard 周期筛选在 SQL 层**(`watchRecordsSince`,`createdAt >= since`),非全量拉回客户端过滤。
3. **nUSD→USDT 换算 = /1e9**(镜像上游 portal `formatNusd`,`NUSD_PER_USDT=1e9`,6 位小数):Dashboard 聚合收益(KPI「收益(USDT)」+ 模型明细)显示 USDT;Records 逐笔保留 nUSD 原值(对齐上游 records 表「金额 nUSD」)。链上卡 `receivedUsdt` 是链上 USDT raw(6 位)→ /1e6。**勿混淆**:nUSD 是 nano(1e9/USDT),与 USDT 链上 6 位 raw 是不同量纲(等价 USDT-raw = nUSD/1000)。
4. **厂商汇总[进阶]未做**:provider_log 无 vendor 列,厂商汇总需 modelName→quotation→vendor join;模型明细(group by modelName)已直接落地,厂商汇总留 Fog。
5. **状态映射去重**:新增 `status_visuals.dart` 共享,app_shell 删本地副本,Dashboard 复用(Rule 7:一处真值)。

**留尾(毕业新票 / Fog)**:
- 桌面常驻(系统托盘 + 单进程 keep-alive)→ **10**(平台原生,无上游参考)。
- friendlyError + 本地日志 + 国际化骨架 → **11**(横切基础设施)。
- 全功能割接验证(WS/crypto/对账端到端一致)→ Fog(被真实 Polygon 配置 + operator settle 阻塞,dev 跑不通)。
- 厂商汇总、失败率告警[进阶]、Dashboard 低余额告警 → Fog。

**测试**(+11 → 209):provider_log `watchRecords`(3:无筛选倒序/按状态/双维度)+ `computeLlmMetrics`(3:锁完成率·计费额只计 completed 的业务含义/模型明细倒序/空→empty)+ ws_client 心跳 RTT(1:发-收-停止清零)+ records widget(2:列表绑定+徽章+失败原因/空态)+ dashboard widget(2:KPI+明细+链上汇总+健康绑定[override 掉 NodeService/ChainWatcher/身份避免真起 WS/keychain]/空态)。
