# 07 — 功能对齐范围(v1 scope)

Type: grilling
Status: resolved (2026-08-08, supplier-portal session)

## Question

provider-portal 的 9 个功能页 + provider-server 能力,**哪些进 v1、哪些 defer、哪些 web 概念在 app 里要重映射或舍弃**?

9 页:Dashboard / Keypair / Wallet / Models(报价)/ Providers(LLM 厂商配置)/ Chain-settlements / Records / Settings / **Env(.env 编辑器——app 里没有 .env 文件,需重映射为"应用配置")**。

逐页确认 v1 范围与 app 形态。relay-sync 类功能(拉报价 / resync)确认能用现有 WS `query_*` 实现(关联 Fog)。

## Context

- provider-portal 页面:`../web3-api/packages/provider-portal/src/app/`(9 个路由)。
- provider-server 能力:forwarder / event-watcher / ws-client / keypair(见 explore 报告)。

## Done looks like

v1 功能清单(in / out)+ 每页 app 形态一句话 + defer 项。用 /grilling。**此 ticket 给所有实现 ticket 划定边界**——先于具体实现。

## Answer

**姿态 A（近乎完整对齐，按页内丰度分层而非整页砍）**，经 /grilling 逐项确认。

> recon 见会话内 Explore 报告。**纠正**：agent 误读为「app 调 provider-server REST 当薄客户端」——**作废**。已定决策（CONTEXT.md + map + 6 个已 resolve ticket + 开放 09）明确：**app 取代 server，自身即节点**。agent 的 per-page 功能描述与 `query_*` 清单准确可用；其「迁移成本表」与「关键发现」建立在错误前提上，作废。真实视角：app 吃掉 server 后，agent 列的每个 REST 端点都要变 app 内逻辑重写。

### v1 IN（8 页，Env 折叠进 Settings）

| 页 | v1 形态（一句话） | defer 项 |
|---|---|---|
| **Dashboard** | 顶部**节点健康面板**（app 原生新增：WS 态 / 转发中 / 最近心跳 / 低余额，吃 05 NodeService 状态机 enum）+ 4 分析板块（周期统计 / 厂商汇总 / 模型明细 / 链上看板）+ 24h\|7d\|30d\|lifetime | 模型明细失败率视觉告警 |
| **Keypair** | 生成/导入助记词（BIP-39，01/10）+ AES-256-GCM 本地存（06）+ 密码解锁；**首次运行强制聚焦 modal**（助记词只展示一次 + 确认备份 + 解锁）；**自动恢复**（opt-in、桌面默认开、解锁凭证存 OS keychain macOS 原生、永不额外持久化助记词明文；冷启动读 keychain 自动解锁重连，否则锁定等待） | — |
| **Models** | relay_model→厂商/模型/报价 CRUD；relay-sync：上报报价（`provider_info`，必需）+ 同步模型元数据（`query_model_params`，选择器） | 从中转站拉报价覆盖本地（`query_provider_models`） |
| **Providers** | 厂商 name/endpoint/key/models/adapter-type/supports-stream CRUD；逐模型连通测试（Hi 探测，成败 + 错误） | 失败后自动探测候选 endpoint |
| **Chain-settlements** | Settled 事件只读表（可过滤）+ 全量同步逃生口（从某区块 / 全量重扫） | 逐行按 tx+logIndex 对账（`query_relay_records_by_tx_logindex`） |
| **Records** | provider_log 只读流水（按状态筛选） | — |
| **Settings** | owner/payment 地址 + relay WS url 只读（链上 `wsUrl()`）+ WS 状态；**吸收 Env**：网络选择器（dev/mainnet/testnet 主开关）+ 可编辑 RPC URL（启动必填）+ 浏览器 tx 前缀 + 高级折叠（合约地址派生只读 / 回补窗口） | — |
| ~~Env~~ | **整页删除**（app 无 .env），重映射进 Settings | — |

### v1 OUT（defer 到 v1.1）

- **Wallet 页**：余额已由 Dashboard 链上板块 + 节点健康低余额告警承载；交易历史（Etherscan 代理）+ `POLYGONSCAN_API_KEY` 出 v1。
- 各页丰度 tier 见上表 defer 列。
- 完整多步引导向导（v1 用混合式：keypair 强制 modal + 其余修红灯，前置满足后节点自动连网）。

### 节点能力（非「页」，但 v1 节点核心，已由已 resolve / 开放 ticket 覆盖）

WS 连接+鉴权+provider_info（03/04/05）、forwarding 管线（09）、provider_log 持久化（06）、链上 watcher（02）、端到端往返（11）。

### 关键 app 原生新增（web 无，后续实现 ticket 需覆盖）

节点健康面板、首次运行 keypair 强制 modal、Settings 网络选择器、OS keychain 自动恢复。

### Fog 消化

- **relay-sync 无需改中转站 ✅**：`query_provider_models` / `query_model_params` / `query_relay_records` / `query_relay_records_by_tx_logindex` / `query_settlement` 均存在（03 已析），relay-sync 功能全用现有协议 → 清 Fog「中转站 WS 协议是否需扩展」。
- **私钥跨端安全存储**：v1 用 macOS Keychain 原生（自动恢复需要）；统一跨端抽象仍留 Fog。

### 后续

v1 页面实现波次（8 页 + app 原生新增）的 ticket 待 08（视觉方向）/ 09（forwarder）resolve 后再精确化（见 map Fog）。07 不创建实现 ticket，避免在视觉未定前过度 chart。
