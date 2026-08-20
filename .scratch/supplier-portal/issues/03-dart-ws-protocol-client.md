# 03 — WS 协议客户端可行性(Dart)

Type: research
Status: resolved

## Question

能否在 Dart 实现中转站 WS 协议的**客户端侧**,完整跑通供应商节点的消息回路?

- 握手:连 `:3003` → 收 `auth_ack`(success=false, challenge)→ EIP-191 签名 → 发 `auth` → 收 `auth_ack`(success=true)→ 发 `provider_info` → 30s 心跳(60s 超时断)。
- 入站路由:`llm_request` / `llm_stream_cancel` / 各 `query_*` 响应。
- 出站:`llm_response` / `llm_stream_chunk` / `llm_stream_end` / `llm_error` / 各 `query_*` 请求。
- 断线重连策略(指数退避?重连后重新握手 + 重发 provider_info?)。

## Context

- 协议权威:`../web3-api/packages/shared/src/protocol/messages.ts`(全消息目录 + payload 形状)。
- 上游客户端:`provider-server/src/ws/client.ts`;服务端:`relay-server/src/ws/server.ts` + `auth.ts` + `connection-pool.ts`。
- Dart 库:`web_socket_channel`(基础)。依赖 01(SIWE 签名)。
- **此 ticket 解锁 05(架构)与 09(forwarder 设计)**——节点能否独立 isolate 运行、forwarder 如何接入,都等它。

## Done looks like

markdown:握手能否跑通(最好对真实中转站冒烟,配合 04)+ Dart 消息类对应 `messages.ts` 的编解码方案 + 心跳 / 重连方案 + 已知坑。资产链接挂本 ticket。

## Answer

**可行 ✅——纯 JSON-over-WS 协议,17 个 type,无二进制 frame / 无压缩;唯一密码学依赖 EIP-191 `personal_sign` 已由 01/10 解决。** `web_socket_channel` + 手写 sealed message 映射 + `Timer.periodic` 心跳即可覆盖全部功能。完整研究资产:[`assets/03-dart-ws-protocol-findings.md`](../assets/03-dart-ws-protocol-findings.md)(逐行源码引用)。

要点速览(详情见资产):

- **握手**:连 `:3003` → 服务端主动推 `auth_ack(success:false, challenge)` → 对 challenge **明文字符串原文**做 EIP-191 签名 → 发 `auth{address,paymentAddress,signature}` → `auth_ack(success:true)` → 500ms 后发 `provider_info`。challenge 是 SIWE-shaped UTF-8 字符串(地址处是占位 zeroAddress,只签原文勿重建),nonce 一次性,TTL 60s。
- **编解码方案**:手写 `sealed class RelayMessage` + 按 `type` 分派 `fromJson`/`toJson`(不要全量 codegen)。**关键陷阱:`query_settlement` / `_result` / `_error` 三条不走 `{type,payload}` envelope,顶层平铺且用 `tx` 关联,解析入口须先拦截。** LLM 子结构必须留 `Map<String,dynamic>` 透传兜底,否则丢厂商私有参数。
- **心跳/超时**:应用层 `heartbeat` JSON 消息(非 WS ping);服务端 60s 无心跳硬断。建议 Dart 发送间隔压到 15–20s(TS 是 30s,余量小)。
- **重连**:指数退避 + full jitter(base 1s / cap 60s);重连即重走完整握手 + 重发 provider_info;建议加主动 auth 超时 + 可重试的链上 URL 解析(TS 读失败即永久放弃,需改)。
- **最大行为差异(F.5 #4)**:`web_socket_channel` 不暴露底层 socket → 无法设 TCP keepalive,且 Flutter 后台会挂起 timer → 移动端 60s 内不发心跳即被踢。这是 Dart 侧主要风险,直接关联 Fog「移动端后台保活策略」。
- 其他坑:`provider_info.models` 只发 `relayModel`(TS 多发的 `name` 被服务端丢弃)、`providerSignature` 恒发空串、`llm_stream_cancel` 实为入站、`query_response.data` 形状随查询类型而异。

**真实握手联调(对真实中转站冒烟)属 04 的 scope,本研究为文档级可行性。** 本 ticket 解锁 05(架构)与 09(forwarder)。
