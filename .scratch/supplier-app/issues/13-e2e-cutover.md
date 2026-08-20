# 13 — 全链路 e2e 验证 + 割接形状

Type: grilling
Blocked by: (无;依赖 01–12 全 resolved 的实现 + 真实 Polygon/relay 配置)
Status: resolved (2026-08-09)

## Question

从 map Fog「割接(同供应商身份不两端并存)」毕业。supplier-app 核心 implementation 已完成
(01–12 全 resolved,235 测试绿),但**从未端到端真跑过**——所有链路腿都只有单测,没有一次
贯穿 identity→relay→LLM→计费→链上结算→对账→页面的真实往返。本票是 grilling:把「怎么验证
这次替换真的成立」问精确,产出三件可执行物,让 e2e **可被验证**:

1. **割接形状** —— CONTEXT.md 约束:同一供应商地址只能一条 WS 连中转站,旧 web3-api
   provider-server 与新 Flutter app **不可并存**。定义:停旧→起新的步骤、SIWE/EIP-191 鉴权
   握手如何验证(crypto 互通,即旧 Node 注册的同一助记词在新 app 解锁后能通过 relay 质询)、
   provider_info 上报验收、回滚路径(若新 app 异常如何切回旧 Node)。

2. **e2e 验收路径** —— 串联 01–12 的最小 happy path,逐腿定 must-pass 验收点:
   identity unlock → WS 连 + 鉴权(01)→ relay 路由 `llm_request` → forwarder→LLM→流式流回(02)
   → provider_log 计费(02 amount nUSD)→ operator 调 `settle()` → Settled 监听采集(05/08)
   → 对账回填 provider_log(06)→ Dashboard/Records/Settlements/Wallet 反映(04/07/12)。

3. **配置前置 + 运行环境** —— 8 个 `--dart-define`(RELAY_WS_URL / POLYGON_RPC_URL /
   POLYGON_RPC_URL_WS / POLYGON_CONTRACT_ADDRESS / POLYGON_DEPLOY_BLOCK / POLYGON_USDT_ADDRESS /
   POLYGONSCAN_API_KEY / UPSTREAM_API_KEY)+ app 内助记词 + 一个能调 `settle()` 的 operator(中转站
   操作员,**非** app 用户)。先 Amoy(80002)还是直上 mainnet?已知缺口:`PolygonscanClient`
   chainid 固 137,Etherscan 交易历史在 Amoy 不通(待 Settings 网络运行时切换 ticket 同批毕业)。

产出:割接 runbook + e2e 逐腿验收清单 + 配置项 checklist。**实跑**(需用户配置 + operator
触发 settle)作为后续 task ticket,不在本 grilling 内执行。

## Answer

Grilling 收敛 4 分支(2026-08-09)。产出 = 范围决策 + 配置 checklist + 割接 runbook(含代码级
硬规则)+ 逐腿验收 + 已知限制。**实跑执行 → ticket 14(task)**。

### 1. 范围 = 全本地 Amoy e2e,Tier 1+2,真 LLM

三组件本机同跑:① relay-server(operator key + `SETTLE_MIN_AMOUNT_USDT=0`)② Flutter
supplier-app(替换 provider-server,新身份即可)③ customer `curl` 打 relay OpenAI 端点驱动
一次 `llm_request`,随后手动 settle。operator 依赖消解:relay-server 是兄弟仓,本地起 = 你自己
即 operator。真 LLM key 跑真实流式往返(非 stub)。Tier 2(settle/采集/对账)全量纳入。

### 2. 配置 checklist(三组件)

| 组件 | 项 | 来源/状态 |
|---|---|---|
| relay-server(.env.amoy) | `POLYGON_CONTRACT_ADDRESS` / `POLYGON_USDT_ADDRESS` | 08 smoke 已有(`0x08Eb…28A9` + mUSDT) |
| | `POLYGON_RPC_URL`(+ WS) | 08 smoke Alchemy Amoy key |
| | **`POLYGON_OPERATOR_PRIVATE_KEY`** | ✅ 在手(settle 必需) |
| | `SETTLE_MIN_AMOUNT_USDT=0` / `SETTLEMENT_WINDOW_MINUTES=0` | 测试设 0 |
| | `BATCH_SETTLE_CRON` / 端口(WS 4000 / OpenAI 8080 / admin 4005) | 默认即可 |
| Flutter app(--dart-define) | `RELAY_WS_URL` | 对齐 relay(**注意 :3003 默认 vs :4000 实际**) |
| | `POLYGON_*` 7 项 | 同 relay-server 那套值 |
| | **`UPSTREAM_API_KEY`** | ✅ 真 LLM key |
| | 助记词 | app 内现场生成(新身份) |
| 合约预注资 | 给 `0x08Eb…28A9` mint 足够 mock-USDT | deploy-amoy 不做,**e2e 前置**(否则 settle revert) |
| customer 驱动 | 一个 `sk-relay-*` key 打 relay OpenAI 端点 | relay admin 生成 |

### 3. 割接机制(代码级发现,写入 production cutover runbook)

- **硬规则:先彻底停旧 provider-server,确认 relay 日志 `Provider disconnected: <A>` 后,再起新
  app。** 反过来(先新后旧)致死:`removeByWs(oldWs)` 用 `byWs.get(oldWs)=A` 调
  `providers.delete(A)`,而 `updateByWs` 覆盖时**不清** `byWs[oldWs]` → 停旧动作会删掉刚覆盖成
  的新条目,新 app 静默脱池(`pool.get(A)=undefined` → 新请求全落空)且不重连(它不知被踢)。
  证据:`web3-api/packages/relay-server/src/ws/{server.ts, connection-pool.ts}`。
- 身份 = 助记词,可移植:割接 = 停旧 → 起新、**同助记词**;新 app 派生同地址 A → 过 SIWE/EIP-191
  鉴权即证 **crypto 互通**(relay 日志 `Provider authenticated: A`)+ provider_info 被接受。
- 回滚对称:停新 → 重启旧 provider-server(同助记词)。
- 本地 e2e 为全新搭建(α),不物理重演过渡;crypto 互通等价于「新 app 鉴权成功」(腿 2 覆盖)。
  production cutover 把上述硬规则作安全门。

### 4. 逐腿验收(9 腿一次连续运行全绿 = PASS)

| # | 腿 | must-pass 信号 | ticket |
|---|---|---|---|
| 1 | identity 解锁 | 助记词生成/导入 → 解锁 → 派生地址 A | M1 |
| 2 | WS 连 + 鉴权 | relay 日志 `Provider authenticated: A`;app 收 `auth_ack{success:true}` | 01 |
| 3 | provider_info 上报 | relay `/admin/providers` 列出 A + 模型清单/报价 | 02 |
| 4 | 真实往返 | customer curl 打 relay OpenAI 端点 → 收到**流式**完整响应 | 02 |
| 5 | 计费落库 | app `provider_log` 一行:`amount=round((in×prompt+out×completion)/1000)` nUSD、`completed`;Records 页可见 | 02/04 |
| 6 | operator settle | relay `runSettleOnce("manual")` → Amoy 上链 Settled tx;relay_log 标 `on_chain_settled` | (relay) |
| 7 | Settled 采集 | app watcher 收事件 → 解码 → 写 `provider_chain_settlement` | 05/08 |
| 8 | 对账回填 | syncer `query_relay_records_by_tx_logindex` 命中 → provider_log 标 `on_chain_settled`+settle_tx+log_index | 06 |
| 9 | 页面反映 | Dashboard KPI/厂商卡、Settlements 出该 tx 行、Wallet USDT 余额增加 | 04/07/12 |

口径:严格 PASS = 一次连续运行全绿;settle 手动触发(`SETTLEMENT_WINDOW_MINUTES=0`,不等 cron);
unmatched/09 不重演(单测覆盖);单 customer 请求。

### 5. 已知限制(写入 14 + 留 Fog)

- **Wallet tx 历史(Etherscan)**:`PolygonscanClient` chainid 固 137;Amoy(80002)matic/usdt 交易
  历史取不到。腿 9 在 Amoy 只验 USDT **余额读**(getBalance/balanceOf,08 smoke 已证),tx 历史
  待 Settings 网络运行时切换 ticket(Fog)。
- **backfill 冷启动**:Alchemy 免费层 10 块/请求;务必设 `POLYGON_DEPLOY_BLOCK`(贴近当前),
  否则冷 backfill ≈ 海量请求。`watcher.sync({full})` 时注意。
- **合约预注资**:见配置 checklist;e2e 前 mint mock-USDT。
- **WS 端口**:见配置 checklist;确认 `RELAY_WS_URL` 实际端口。

### 6. 派生

- **ticket 14(task)**:按本 Answer 的 runbook + 验收清单实跑全本地 Amoy e2e;blocked by 本票
  (decisions)+ 用户配置就位 + 真机运行(部分可 agent 自动化:驱动脚本/runbook 命令;执行需真 key)。
- Settings 网络运行时切换(Amoy Etherscan chainid)仍在 Fog,不毕业(更广批次,含运行时网络门控)。
