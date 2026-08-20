# Map — 流水·供应商端 (flowing-water-flutter)

> wayfinder map。本文件是**索引,不是存储**——决策细节只活在它的 ticket 里,这里只 gist + 链接。开放 ticket 不在此列出,靠查 `issues/` 找。

## Notes

- **领域**:见 `../../CONTEXT.md`(供应商端视角的 ubiquitous language)。上游权威 `../web3-api/CONTEXT.md`。
- **每次会话先读**:`../../CONTEXT.md`、本 map、`../../docs/agents/*.md`(issue 跟踪 / 标签 / 领域文档约定)。
- **被取代的上游**:`../web3-api` 的 `provider-server`(Node)+ `provider-portal`(Next.js)。协议权威:`web3-api/packages/shared/src/protocol/messages.ts`。
- **UI / 架构参考**:`../listening-king`(Flutter 多端,Provider + Dio + Hive,设计 token 体系,desktop scaffold)。**借架构模式,不借 Duolingo 视觉**。〔视觉方向已定 → 见 [08](issues/08-visual-direction-app-shell.md):C 骨架 + B 顶部摘要 + 近黑/蓝 accent + light 默认。〕
- **已定约束**:供应商端角色 / 全平台内嵌(桌面常驻为节点,移动尽力而为)/ 专业后台风 / 单供应商节点 / 完全替换 Node provider-server。
- **可用库栈(已实测)**:Dart 加密 = `web3dart` + `eth_sig_util` + `bip39` + `bip32`(与 viem 完全互通,见 10)。
- **运行约定**:本地 markdown 跟踪器,本 effort 在 `.scratch/supplier-portal/`;ticket = `issues/NN-<slug>.md`,`Type:` / `Blocked by:` 行在文件头,`Status:` 记 `claimed`/`resolved`(开放 ticket 无 `Status:`)。**一个会话最多 resolve 一个 ticket。**

## Decisions so far

<!-- 一行一个已 resolve 的 ticket:一句话 gist + 链接 -->

- [01 · Dart 加密栈可行性](issues/01-dart-crypto-feasibility.md) — **可行 ✅**:全标准算法 + Dart 成熟库;`providerSignature` 恒为 `""` 无需签(解除 09 对 01 依赖);AES 本地自定;迁移靠同助记词重导入。
- [02 · Polygon 链交互可行性](issues/02-dart-chain-interaction.md) — **全可行 ✅**:web3dart 3.0.3 原生覆盖 4 项(WS `events()`+`socketConnector` 真订阅/降级轮询、`getBalance`+`call balanceOf`、`sendTransaction` EIP-1559、`getLogs`→`FilterEvent` 显式 decode)。不新增依赖。镜像上游 WS 主 + getLogs 分页回补 + 游标 + 退避重连。**转账上游无参考实现(净新增)**;解码无 `.decoded` 需显式调;配置项归 05/06。
- [03 · WS 协议客户端可行性(Dart)](issues/03-dart-ws-protocol-client.md) — **可行 ✅**:纯 JSON-over-WS、17 type、无二进制;EIP-191 鉴权依赖已解。`web_socket_channel`+手写 sealed 消息映射+`Timer.periodic` 心跳全覆盖。坑:`query_settlement` 三条破坏 envelope(用 `tx` 关联须特判)、challenge 是 SIWE 明文(只签原文勿重建)、`provider_info.models` 只发 `relayModel`、`providerSignature` 恒空串。心跳建议 15–20s(服务端 60s 硬断);重连指数退避+full jitter、重连即重握手。最大风险:`web_socket_channel` 无 TCP keepalive + Flutter 后台挂起 timer → 移动端心跳断(关联 Fog「移动端后台保活」)。解锁 05/09。详情见 `assets/03-dart-ws-protocol-findings.md`。
- [10 · 加密互通验证 spike](issues/10-crypto-interop-spike.md) — **实测互通 ✅**(`web3dart`/`eth_sig_util`/`bip39`/`bip32` ↔ viem):助记词→地址一致、EIP-191 签名逐字节相同、`viem.verifyMessage(Dart sig)=true`。库栈锁定;真实握手联调待 04。
- [04 · 中转站部署 + Dart WS 握手冒烟](issues/04-relay-connection-and-handshake.md) — **通过 ✅**:本地 dev relay(`ws://localhost:3003`,空合约 / 无 operator keypair 即可)完整握手跑通——收 SIWE challenge → Dart EIP-191 签名 → relay `auth_ack{success:true}`(viem 验 Dart 签通过)+ `provider_info`(relay log `reported 1 models, stream=true`)+ `heartbeat` 回包。**01/10 互通在真实 relay 交叉验证**。spike `spikes/ws-handshake/dart-spike`;runbook `spikes/ws-handshake/RELAY-STARTUP.md`。新增 11(端到端 LLM 往返,blocked by 05/09)。
- [06 · 本地持久化选型](issues/06-local-persistence-choice.md) — **drift(单库)✅**:否 Hive/Isar;与上游 better-sqlite3 schema **1:1 对齐**(provider_log 3 索引 + chain_status CHECK + 时点价快照查询 = 真关系负载,listening-king 的 Hive 不成型),parity 验证成本最低。11 表同名直译(注:`provider_chain_settlement` 金额须 TextColumn/BigInt;旧名 `llm_providers`→`provider_llm_vendor`、`model_params`→`provider_models`)。v1 不自动清理、桌面全量;fresh start + 文件级拷贝逃生路径;schema 实现分层与割接计划待 05。
- [05 · 应用架构与状态管理](issues/05-app-architecture-state.md) — **定稿 ✅(仅桌面端,移动延后)**:Riverpod(自带 DI + `AsyncValue` 统一 loading/error + override 测试注入,替代 listening-king 脆弱 `forTest`)+ go_router(`StatefulShellRoute` 桌面嵌套 shell + `redirect` 鉴权守卫)+ feature-first 目录(`core/`=节点基础设施 / `features/`=UI / `shared/`=设计 token)。节点 = **托盘驻留单进程 + 主 isolate**(重活 `compute()` 卸载,不另起 isolate);移动端整体延后。NodeService = keepAlive provider,**鉴权驱动 + supervisor**(异常自动重启带退避),连接态对外暴露状态机 enum、errors-as-state。骨架目录约定见 ticket。解锁 09 上下文;11 现仅余 09。
- [08 · 视觉方向与应用外壳](issues/08-visual-direction-app-shell.md) — **C 骨架 + B 顶部摘要嫁接 ✅**:app 双重身份(常驻算力节点=监控 / 9 页管理后台),故混搭——布局密度取 **C**(发丝边框/无重阴影/窄侧栏 208/圆角 3–5/紧凑),顶部嫁接 **B**(4 KPI 卡 + 绿「Connected」pill);主色 = 近黑 `#111827` 结构 + 克制蓝 `#2563EB` accent + 语义色;**light 默认、暗色延后**(A terminal 色板作暗主题蓝本);响应式 AppShell(宽屏侧栏/窄屏底导航)采纳。原型 `spikes/visual-direction/dart-spike`(analyze 净 + macOS build 过)。token 展平回 `AppColors`/`AppTheme` + 搬 shell/Dashboard 待真实 app 脚手架(下游实现)。
- [07 · 功能对齐范围(v1 scope)](issues/07-feature-parity-scope.md) — **v1 = 8 页(Env 折叠进 Settings),姿态 A 近完整对齐 + 页内丰度分层**。Dashboard 加**节点健康面板**(app 原生,吃 05 状态机;与 08 顶部「Connected pill」同源);Keypair 首次强制聚焦 modal + **自动恢复**(OS keychain 存解锁凭证、桌面默认开、永不持久化助记词明文);Settings 加**网络选择器**(dev/mainnet/testnet)+ 可编辑 RPC;**Wallet 页 defer v1.1**(余额归 Dashboard 链上板块 + 节点健康低余额告警);各页 defer 项见 ticket。relay-sync 无需改中转站(清 Fog)。**纠正** recon:app 自身即节点、取代 server,非薄客户端。**08 的「9 页」→ v1 实为 8 页**。解锁 v1 页面实现波次(待 09 + 真实脚手架)。
- [09 · Forwarder / Adapter 架构](issues/09-forwarder-adapter-architecture.md) — **定稿 ✅**:镜像上游 `ProviderAdapter` 三方法(`buildRequest`/`parseResponse`/`parseStreamLine`)+ 5 适配器工厂(逐调用新实例,Anthropic 带 per-stream `openToolUses` 状态;DeepSeek/Azure 委托 OpenAI)。流式管线 = **dio** `ResponseType.stream` + 逐行 SSE(Gemini 走 JSON 流分支)+ 30s 空闲 `Timer` 超时 + Content-Type 校验。**取消**:`StreamDispatcher` 持 `Map<requestId,CancelToken>`,`llm_stream_cancel`→`cancel()`→dio 中止→onError;WS 断开 `abortAll()`。**接口契约**:`RelayClient`(03)↔ dispatcher 四消息(llm_request/chunk/end+`providerSignature:""`/error/cancel),requestId 由中转站分配,chunk 串行保序,end 后无消息。`provider_log` 在 dispatcher 层插桩(insert 时点价快照 / complete amount=round((in×prompt+out×completion)/1000) / fail)。**无需 crypto**(01 解除依赖)。落 `core/forwarder/`,主 isolate。**解锁 11**(05+09 均解)。
- [11 · 端到端 LLM 往返冒烟(对真实 relay)](issues/11-e2e-llm-roundtrip-smoke.md) — **通过 ✅**:接入方 `/v1/chat/completions`(stream)→ relay → Dart provider(openai adapter)→ SenseNova 真实上游 → 流式回包,端到端可见;本地 provider_log 与 relay 侧 relay_log **对账一致**(input/output/amount 逐字段相同,如 12/681/1 nUSD)。adapter=openai、model=sensenova-6.7-flash-lite、key 经 `UPSTREAM_API_KEY` 环境变量传入(不落盘)。协议偏差:`providerSignature`/`relaySignature` 恒 `""`(✅与 03 一致);上游 `reasoning`/`role:null` 等非标准字段经 adapter "spread delta verbatim + 保留顶层非标准字段" **原样透传未丢**(P0~P3 验证通过);usage 在末尾 `choices:[]` 独立 chunk,`usageReported=true` 无 silent-billing。坑:完成时序须用 `Completer` 等往返真结束(非固定 delay),否则长答案(15s)穿透致 WS 早断、relay 误标 `client_disconnected`。

## Fog

<!-- 看得见但还说不精确的决策/调查;能精确成问题时就毕业成 ticket -->

- **迁移割接与行为对齐验证** — 完全替换 Node provider-server,需要割接计划 + 验证 Flutter 节点与原 Node 行为一致(WS 协议兼容、crypto 互通、结算对账一致;同一供应商身份不能两端并存)。〔crypto 已实测互通(见 01/10);关键约束:老供应商链上地址不可变 → 用同一助记词在 Dart 重导入,不迁移密文。〕形状待架构(05)明朗后精确化;**05 已定桌面单进程基线**;**03/04 已实证 WS 协议兼容 + crypto 互通 + 真实握手链路(本地 dev relay)成立**;**09 已定 forwarder 架构(镜像上游 adapter 抽象 + 流式管线 + 取消语义)**。剩余行为对齐 = **结算对账**(llm 往返已由 11 实证一致——见下)。割接形状待「结算对账」成型后精确化。〔**11 已通过:端到端流式往返打通,本地 provider_log 与 relay 侧 relay_log token/amount 对账一致;providerSignature/relaySignature 恒空串确认;上游非标准 reasoning 字段经 adapter verbatim 透传未丢**——割接验证的「llm 往返行为一致」✅。06 已定:app 数据 fresh start;但持久化 drift + schema 1:1 对齐 → 「旧 Node SQLite 文件直接拷入 drift 打开」为零成本逃生路径,割接时可选,无需写导入代码。〕
- **移动端后台保活策略** — Android foreground service?iOS background task?还是移动端只做降级监控(连桌面节点 / 只读连中转站)?〔**05 已定基线**:本架构仅桌面端,移动端整体延后;同一供应商身份 = 单 WS 连接 + iOS 后台 WS 不可能 → 移动端不当服务节点,定为观察/管理客户端。剩余开放子问题 = 移动端数据来源(连自己桌面节点 / 只读连中转站),待移动端启用时再定。〕
- **多端打包 / 签名 / entitlements** — macOS/Windows/iOS/Android 构建配置、网络客户端 entitlements(出站 WS)、代码签名。远期,依赖平台决策成熟。
- **节点可观测性** — always-on 节点的监控 / 告警 / 日志体系(WS 断连、转发失败、余额低、对账异常)。待核心功能成型。〔07 已把「节点健康面板」定为 v1 Dashboard 顶部组件——可视层入 v1;但告警 / 日志后端体系仍待核心功能成型。〕
- **私钥跨端安全存储** — 助记词 / 私钥除 AES-256-GCM 外,各平台 secure storage(Keychain / Keystore / Windows Credential)的统一抽象。〔07 已定 v1 用 macOS Keychain 原生(自动恢复需要解锁凭证持久化);跨端统一抽象仍留 Fog。〕
- **国际化** — 中 / 英文(上游文档与 listening-king 均中文优先)。低优先。
- **暗色模式双主题** — 08 定 light 为默认,暗色列为正式特性但延后(A terminal 色板作暗主题蓝本)。待核心成型后定双主题 token 结构(是否把 `DirPalette` 拆 light/dark 两套 / `AppTheme` 双 getter)。
