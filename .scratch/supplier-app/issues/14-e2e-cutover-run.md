# 14 — 全本地 Amoy e2e 实跑(按 13 runbook)

Type: task
Blocked by: 13(decisions 已 resolved);执行还需用户配置就位 + 真机运行
Status: (开放;agent 预备已完成,执行待用户)

## Question

按 [13](13-e2e-cutover.md) 的 `## Answer`(范围 / 配置 checklist / 割接 runbook / 9 腿验收 /
已知限制)实跑一次**全本地 Amoy e2e**,真 LLM,Tier 1+2。目标:9 腿一次连续运行全绿 = cutover
readiness 闭环。

agent 可自动化部分:customer 驱动脚本(curl 打 relay OpenAI 端点)、runbook 命令清单、结果采集。
需用户/真机部分:relay-server 起带 operator key + Amoy 配置、Flutter app `flutter run -d macos`
真跑、真 LLM key 注入、合约 mint mock-USDT、手动 `runSettleOnce`。

## Done looks like

- [ ] **配置就位**:relay-server `.env.amoy`(operator key + `SETTLE_MIN_AMOUNT_USDT=0` +
      `SETTLEMENT_WINDOW_MINUTES=0` + Amoy 合约/RPC)+ Flutter app `--dart-define`(8 项,`RELAY_WS_URL`
      对齐 :4000)+ 合约 `0x08Eb…28A9` mint mock-USDT + `POLYGON_DEPLOY_BLOCK` 设贴近当前。
- [ ] **起三组件**:relay-server → Flutter supplier-app(新助记词)→ 验腿 1–3(identity 解锁 /
      `Provider authenticated: A` / `/admin/providers` 见 A)。
- [ ] **腿 4–5**:customer curl 打 relay OpenAI 端点 → 流式响应;app `provider_log` 一行 completed +
      `amount` nUSD;Records 页可见。
- [ ] **腿 6–9**:手动 `runSettleOnce("manual")` → Amoy Settled tx → app watcher 采集 → 对账回填
      provider_log → Dashboard/Settlements/Wallet 反映(Wallet 仅验 USDT 余额读,tx 历史待 Settings
      网络切换)。
- [ ] **记录**:实跑日志 + 每腿 must-pass 信号取证(relay 日志 / app DB / 链上 tx / 截图),写入
      本票 `## Answer`;失败腿记根因 + 是否需新 ticket。
- [ ] **割接 runbook 落地核验**:确认「停旧优先 + 等 `Provider disconnected` 日志」安全门写入运维
      文档(13 已给代码证据)。

## Notes

- 腿 9 Wallet tx 历史(Etherscan)在 Amoy 取不到(chainid 固 137)——只验余额读;见 13 已知限制。
- backfill 冷启动:务必设 `POLYGON_DEPLOY_BLOCK`;否则 Alchemy 免费层 10 块/请求致海量请求。
- unmatched/09 路径不在本票重演(单测覆盖);仅走 happy matched。
- 若实跑暴露新集成 bug → 开新 ticket,本票记「blocked on <X>」。

## Runbook(可执行命令,2026-08-09 agent 预生成)

端口:relay OpenAI `:8080`、admin `:4005`、WS `:4000`。admin 头 `Authorization: Bearer $RELAY_ADMIN_API_KEY`。
driver: [`e2e/customer-request.sh`](../e2e/customer-request.sh)。

**Tier 0 — 配置就位(一次性)**

1. relay-server 用 Amoy profile 起(见 `web3-api/packages/relay-server` 启动方式):`.env.amoy` 含
   `POLYGON_CONTRACT_ADDRESS=0x08Eb…28A9` / `POLYGON_USDT_ADDRESS` / `POLYGON_RPC_URL`(+WS)/
   `POLYGON_OPERATOR_PRIVATE_KEY` / `SETTLE_MIN_AMOUNT_USDT=0` / `SETTLEMENT_WINDOW_MINUTES=0`。
2. **合约预注资**:给 `0x08Eb…28A9` mint 足够 mock-USDT(settle 从合约付供应商,空则 revert)。
   ⚠️ deploy-amoy 不做此步;需对 mUSDT(MockERC20)发 mint 调用 —— **确认 mUSDT 的 mint 访问权限
   (minter=deployer?public?)后再发**,勿臆造命令。
3. 记 `POLYGON_DEPLOY_BLOCK`(贴近当前块)给 app,限冷 backfill。

**Tier 1 — 收入腿**

4. 起 relay-server → 验 `:4000` WS、`:4005/health`、`:8080`。
5. 载 operator key:`POST :4005/admin/keypair/import` → `POST :4005/admin/keypair/load {password}`
   → `GET :4005/admin/keypair/status` = loaded。
6. 起 supplier-app:
   `flutter run -d macos --dart-define=RELAY_WS_URL=ws://localhost:4000 --dart-define=POLYGON_RPC_URL=… --dart-define=POLYGON_CONTRACT_ADDRESS=… --dart-define=POLYGON_USDT_ADDRESS=… --dart-define=POLYGON_DEPLOY_BLOCK=… --dart-define=POLYGON_RPC_URL_WS=… --dart-define=POLYGONSCAN_API_KEY=… --dart-define=UPSTREAM_API_KEY=…`
   - app 内:生成助记词 → 解锁 → 地址 **A**;Models 页配 relayModel + 报价(触发 provider_info 上报)。
7. **腿 1–3 验收**:app 解锁+地址 A;relay 日志 `Provider authenticated: <A>`;
   `GET :4005/admin/providers` 列出 A + 模型清单。
8. 造 customer + key:`POST :4005/admin/customers {name:"e2e"}` → `cust-xxx`;
   `POST :4005/admin/api-keys {name:"e2e",customer_id:"cust-xxx"}` → `sk-relay-xxx`。
9. **腿 4–5 验收**:`API_KEY=sk-relay-xxx MODEL=<relayModel> bash e2e/customer-request.sh`
   → 终端见流式 SSE;app Records 页一行 `completed`;DB `provider_log` 有 `amount` nUSD。

**Tier 2 — 结算腿**

10. **腿 6**:`POST :4005/admin/monitor/settle`(Bearer admin key)→ Amoy Settled tx;relay `relay_log` 标 `on_chain_settled`。
11. **腿 7–8**:app watcher 收 Settled → 解码写 `provider_chain_settlement`;syncer
    `query_relay_records_by_tx_logindex` 命中 → `provider_log` 标 `on_chain_settled`+settle_tx+log_index。
12. **腿 9**:Dashboard KPI/厂商卡、Settlements 出该 tx 行、Wallet **USDT 余额**增加(tx 历史待 Settings 网络切换)。

**PASS = 9 腿一次连续运行全绿。** 失败腿记根因到本票 `## Answer`;新 bug → 开新 ticket。

## Comments

- **2026-08-09(agent 预备)**:本会话(13 grilling 之后)把 14 的 agent 可自动化部分做完:
  - [`e2e/customer-request.sh`](../e2e/customer-request.sh) —— 腿 4–5 驱动(curl 流式打 relay OpenAI 端点)。
  - 本票 `## Runbook` —— 落地为可执行命令(端口/端点/dart-define/settle 触发全核实于 `web3-api/packages/relay-server/src/http/{app,llm.routes,admin.routes,auth.middleware}.ts`)。
- **执行(待用户)**:relay-server Amoy 起带 operator key + 合约 mint mock-USDT + `flutter run -d macos`
  + 真 LLM key 注入 + 手动 settle —— 这些需真 key/真机,agent 不替跑。按 Runbook 走,9 腿全绿即 resolve。
- ⚠️ Runbook 步骤 2(合约 mint mock-USDT)的 mUSDT mint 访问权限未确认 —— 执行前先核实,勿臆造命令。

