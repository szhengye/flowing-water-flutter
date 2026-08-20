# 01 — WS 客户端 + 节点核心

Type: task
Blocked by: (无;依赖 M0/M1 基线)
Status: resolved

## Question

把 app 作为供应商节点连上 relay,完成鉴权并上报模型 —— 为 02(forwarder)的 `llm_request` 收发铺路。

## Done looks like

- **NodeService**(Riverpod `keepAlive` + supervisor 异常自动重启退避 + 连接状态机 enum:`stopped/connecting/authenticating/connected/reconnecting/failed`,errors-as-state 对外暴露、不抛给 UI)。
- **ws_client**(`web_socket_channel`):connect → `auth_ack{challenge}` → EIP-191 签(M1 `signing.dart`)→ `auth` → `auth_ack{success}` → 延迟 500ms 发 `provider_info`;心跳 15–20s(`Timer.periodic`);重连指数退避 + full jitter(基 1s,封顶 60s),重连即重握手 + 重发 `provider_info`。
- **sealed 消息映射**(17 type);`query_settlement`/`_result`/`_error` 三条破坏 `{type,payload}` envelope,dispatch 前特判(姊妹 03 坑)。
- **provider_info 上报**:`models[]` 只发 `relayModel`(姊妹 03);model 列表暂从 drift `provider_quotation` 读(空则上报空列表)。
- **Settings 页落地**:Owner/Payment 地址 + relay WS URL(只读,from 合约 `wsUrl()`,M0 AppConfig 占位)+ WS 状态 + 网络选择器(dev/mainnet/testnet)+ 可编辑 RPC。

## Context

- 依赖 M1 签名 + M0 架构/drift。
- 协议时序见姊妹 spike `../supplier-portal/issues/03-dart-ws-protocol-client.md` + `04-relay-connection-and-handshake.md`(握手冒烟 runbook)+ `assets/03-dart-ws-protocol-findings.md`。
- 本地 dev relay runbook:`spikes/ws-handshake/RELAY-STARTUP.md`。
- 可复用 spike 握手代码:`spikes/ws-handshake/dart-spike/bin/handshake.dart`。

## Comments

### 2026-08-08 — Slice A(协议层)完成;01 仍 claimed,跨会话进行中

本会话(受 CLAUDE.md Rule 6 单会话预算约束)只推进 01 的 **Slice A**,B/C/D 留待后续会话。实现计划见 `~/.claude/plans/peppy-crunching-kitten.md`。

**Slice A 已交付(协议消息层):**
- `lib/core/relay/messages.dart` —— `sealed RelayMessage` + 握手四型(Auth / AuthAck / ProviderInfo / Heartbeat)+ 非 envelope 的 `query_settlement` 三型 + `UnknownRelayMessage` decode 兜底;`encodeMessage`(仅出站)/ `decodeMessage`(入站全派发,未知→兜底,畸形 JSON 抛 `FormatException`)。
- `test/core/relay/messages_test.dart` —— 12 测试全绿;`flutter test` 全量 39/39 通过;`flutter analyze` spikes 外零 issue。
- 只发了 `relayModel`(不发 TS 的 `name`);非 envelope 三型按 `type` 先拦截(守住姊妹 03 的坑);入站型 encode 抛 `UnsupportedError`(provider 永不发送)。

**01 的 5 处 Node↔ticket 差异(已择定,后续 Slice 沿用):**
1. 重连:**full jitter**(base 1s, cap 60s)—— Node 无 jitter,ticket 要 jitter。
2. 心跳:**15s** —— Node 30s,ticket 15–20s。
3. provider_info 源:**`provider_quotation`**(空则空列表)—— Node 读 buffer;buffer flush 归 02。
4. 状态机:**6 态 enum** —— Node 仅布尔。
5. supervisor:**NodeService 内置重连循环 = supervisor**;仅非瞬态错误(无私钥/反复 auth 拒绝)进 `failed` 暴露 UI —— Node 无(靠 Docker)。

**剩余(后续会话):**
- **Slice B** `lib/core/relay/ws_client.dart` —— WS 抽象为可注入 `RelayChannel`(真实包 `WebSocketChannel.connect`,测试用 fake);握手 + 500ms provider_info + 心跳 + full-jitter 重连。
- **Slice C** `lib/core/relay/node_service.dart`(6 态状态机 + supervisor + 身份门禁)+ `providers.dart`(+ `nodeServiceProvider` keepAlive)+ `app_shell.dart`(激活)。
- **Slice D** `lib/features/settings/settings_screen.dart` + `app_router.dart`(`/settings` 特判)。

## Answer

**01 已实现并验证**(2026-08-08,Slice A→D 连续完成)。app 现可作为供应商节点连本地中转站:身份 unlocked 即自动 SIWE/EIP-191 握手 → 上报 provider_info → 心跳 → 断线 full-jitter 重连;6 态状态机对外暴露,Settings 页可观测。全量 `flutter test` 49/49 绿,`flutter analyze` spikes 外零 issue。

**交付:**
- 协议层 `lib/core/relay/messages.dart` —— sealed 18 型 + 非 envelope `query_settlement` 三型特判 + `UnknownRelayMessage` decode 兜底(畸形 JSON 抛 `FormatException`)。`+ test`(12)。
- 传输 `lib/core/relay/ws_client.dart`(+`relay_channel.dart`)—— 握手 / 心跳(15s)/ full-jitter 重连(1–60s)/ auth-failed 终态;时间依赖与通道工厂可注入。`+ test`(6)。
- 编排 `lib/core/relay/node_service.dart` —— 6 态 `NodeStatus`(与 `WsPhase` 映射)+ 身份门禁(unlocked 连 / locked·none 断)+ `_gen` 守卫防切换竞态 + keepAlive;`relayChannelFactoryProvider` 可注入。AppShell `_StatusCard` watch `nodeStatusProvider` 激活。`+ test`(3,含集成)。
- Settings `lib/features/settings/settings_screen.dart` + 路由 `/settings` —— Owner/Payment 地址、relay URL(只读)、实时 WS 状态、当前网络。`+ test`(1)。

**已知后续(被依赖门控,非 01 核心缺口):**
- 「运行时网络切换 + 可编辑 RPC」—— mainnet/testnet 的 relay URL 须从合约 `wsUrl()` 取(见 Fog),Polygon RPC 属 M4 链;故 Settings 暂只读,不开误导性开关。
- provider_info 模型暂读 `provider_quotation`(ticket 择定);02 Models 页 buffer flush 后再接。

**解除阻塞:** 02(forwarder,`llm_request` 收发)与 03(链上结算,`query_relay_records_by_tx_logindex`)现可基于本协议层 + `NodeService.inbound` 推进。
