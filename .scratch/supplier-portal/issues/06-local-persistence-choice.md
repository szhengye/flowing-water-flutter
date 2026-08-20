# 06 — 本地持久化选型

Type: grilling
Status: resolved

## Question

本地持久化选什么?要等价承载 provider-server 的 SQLite 表:

- `settings`(KV)、`llm_providers`(上游厂商配置)、`provider_quotation` / `provider_quotation_buffer`(模型报价 / 草稿)、`model_params`(从中转站同步的模型元数据)、`provider_log`(高频,每条 LLM 调用一条)、`provider_chain_settlement`(链上结算)、`unmatched_settled_events`。
- Records 页要按 `status` / `chainStatus` **过滤查询**(关系型需求)。

候选:**drift**(SQLite,关系查询强,契合 provider_log 高频写 + 过滤)/ **Hive**(listening-king 在用,但关系查询弱)/ **Isar**。

## Context

- 上游表结构:provider-server 的 better-sqlite3 schema(见 `../web3-api/packages/provider-server/src/`)。
- 过滤查询场景:provider-portal `/records` 页。
- listening-king 用 Hive(消费级,无高频关系查询)。

## Done looks like

选型决策 + 表 / Box 映射草案 + 理由(provider_log 高频写 + 关系过滤是关键考量)。用 /grilling。

## Answer

**选型:drift(SQLite),单库承载全部。** 经 /grilling 四问四答定。下游实现待 05(分层形态)。

### 决策

1. **引擎 = drift**(否掉 Hive / Isar)。根因:本项目声明目标(见 Fog「迁移割接与行为对齐」)要 Flutter 节点与被取代的 Node provider-server 行为一致并验证;drift = SQLite,与上游 better-sqlite3 schema **1:1 对齐**(表名/外键/索引/时点价快照查询直译),行为对齐验证成本最低;Isar 是对象 DB,得把关系语义重实现,parity 工作更易引入偏差;Isar 速度优势在本写量下无关紧要。Hive(listening-king 13 个 TypeAdapter、整 box flush、无关系查询)对 `provider_log` 热表不成立——**Hive 仅在 KV 场景可能留席,但见决策 2 已否**。
2. **单库,drift 承载全部**(含 `settings` KV、`chain_sync_cursor` / `provider_chain_poll` 单行游标)。少一个依赖、一套心智模型,避免跨引擎一致性坑;上游本就有 `settings(key,value)` 直译。启动速度非关键路径(always-on 节点:先加载 keypair → 建 WS → 鉴权,drift 开单文件开销不显眼)。**助记词/私钥走 secure storage 抽象,不属 06**(见 Fog「私钥跨端安全存储」)。
3. **v1 不做自动清理,桌面端全量历史**;移动端窗口化裁剪归 Fog「移动端后台保活/降级」。schema 照搬 3 个索引(`processing_status` / `chain_status` / `created_at`),将来加保留策略 = 一条带索引的周期性 `DELETE`,不在 v1 堵路。
4. **v1 fresh start,不写导入 UI / 迁移代码**;因 drift + schema 1:1 对齐,「把旧 Node SQLite 文件直接拷进来 drift 打开」几乎零成本 → **保留文件级逃生路径**(不破坏可能性)。真正割接计划(谁切/何时切/同一供应商地址两端不并存)依赖 05,归 Fog「迁移割接与行为对齐」精确化。

### 表映射草案(上游 v2 schema → drift,1:1,同名)

| 上游表 | PK | 关系/约束 | drift 处理要点 |
|---|---|---|---|
| `provider_log` | request_id | 3 索引(processing_status/chain_status/created_at);`chain_status` CHECK 3 态(not_on_chain/on_chain_settled/on_chain_not_settled);高频写 + 过滤 | IntColumn/TextColumn;CHECK 用 drift CHECK 或 app 层 enum 校验 |
| `provider_llm_vendor` | vendor_id AUTOINC | — | IntegerColumn autoIncrement |
| `provider_quotation` | relay_model_name | FK → provider_llm_vendor | `customConstraint('REFERENCES provider_llm_vendor(vendor_id)')` |
| `provider_quotation_buffer` | relay_model_name | FK → provider_llm_vendor | 同上(草稿态) |
| `provider_quotation_history` | id AUTOINC | 2 索引(submitted_at / relay_model_name);`insertRecord` 时点价快照查询源 | autoIncrement + 索引;被 provider_log 写入路径引用 |
| `provider_chain_poll` | id CHECK(id=1) | 单行游标 | CHECK 约束 |
| `settings` | key | KV | key/value TextColumn |
| `provider_models` | model_name | 中转站同步的模型元数据(原 ticket 写 model_params 是旧名) | — |
| `provider_chain_settlement` | tx | **USDT 金额存 TEXT**(BigInt 安全) | **必须 TextColumn,勿 RealColumn** |
| `chain_sync_cursor` | scope | backfill resume 点(ADR-0003) | — |
| `unmatched_settled_events` | (tx, log_index) | 复合 PK;watcher 重启去重 | drift composite primary key |

> 命名对齐:ticket 里的 `llm_providers` / `model_params` 是 v1 旧名,上游已重命名为 `provider_llm_vendor` / `provider_models`;按当前 v2 名对齐(决策 1 的 parity 前提)。

### 下游(不在 06,仅记录)

- **drift schema 实现**(11 表 + FK + 索引 + 迁移 stepper 镜像上游 v1→v2:rename、chain_status 5→2 收窄)是自然的下一步 task。**05 已定**:feature-first 目录(`core/`=节点基础设施 / `features/`=UI)+ Riverpod → 持久化层(repo / DAO)归 `core/`,以 keepAlive Riverpod provider 暴露(对齐 NodeService 形态)。该 ticket现不再有前置阻塞,**下一会话可开**;本会话不 spawn(一票一会话)。drift 自带 migration 系统,镜像上游 `db/index.ts` 的迁移意图即可。
