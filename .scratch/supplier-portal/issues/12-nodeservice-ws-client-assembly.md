# 12 — M2-1 · NodeService 与 WS 客户端装配:身份接入 + 连接状态机

Type: grilling
Status: resolved (2026-08-08, supplier-portal session —— 本会话 claim 后即 resolve;6 个子问题全部可由 05 + M1 实际接口 + 03/04/spike 直接推出,无交互式 grilling 必要)
Blocked by: (none — M0 脚手架 + M1 crypto 已就绪)

## Question

调查层(01–11)已收口。进入 M2 实现时,承重的第一个设计决策:**always-on 的 `NodeService` 怎么从 M1 的身份层拿到 EIP-191 签名身份、怎么驱动 WS 连接生命周期、怎么对外暴露连接状态机?** 具体要钉死:

1. **签名身份接入** —— M1 的 `providers.dart` 只暴露 `appConfigProvider`/`appDatabaseProvider`/`secureVaultProvider`,**没有 signer provider**。NodeService 从哪里、以什么形态拿到 unlocked 的 `EthPrivateKey`?另起一个 signer provider,还是直接消费 `identityControllerProvider`?
2. **生命周期绑定** —— 05 定了"生命周期绑鉴权状态(注册/登录完成且 provider 就绪后自启,登出停)"。identity 在 none/locked/unlocked 间翻转时,NodeService 的连接该怎么响应?
3. **状态机对外暴露** —— 05 定了 enum `{stopped, connecting, authenticating, connected, reconnecting, failed}` + errors-as-state。谁持有这个状态、UI 怎么读、各 enum 之间的转换条件?
4. **provider 拆分** —— NodeService(keepAlive)、状态机、ws_client 各自是几个 Riverpod provider?职责怎么切?
5. **ws_client ↔ NodeService 边界** —— 握手/心跳/重连/sealed 消息映射落在哪一层?(03/04/spike 已验证握手序列,这里是分层归属。)
6. **目录归属(Rule 7)** —— 05 骨架写 `core/node/` + `core/ws/`;plan 写 `core/node/{node_service,ws_client,messages}.dart`。冲突,需裁定。

## Context

- 05(已 resolve):NodeService = Riverpod keepAlive provider;鉴权驱动生命周期;supervisor(异常自动重启带退避);连接态暴露为显式状态机 enum(errors-as-state)。
- M1 实际接口(读代码确认):
  - `identityControllerProvider`(`AsyncNotifier<IdentityState>`)—— `IdentityState{status: IdentityStatus{none|locked|unlocked}, addressEip55?, keypair?}`;unlocked 时 `keypair` 为内存内 `ProviderKeypair`(私钥+地址),助记词**永不**驻留。
  - `signPersonalMessage(String, EthPrivateKey)` —— EIP-191 `personal_sign`,确定性签名,与 viem 逐字节一致(10)。
- spike `spikes/ws-handshake/dart-spike/bin/handshake.dart`(04 已跑通):connect → 收 `auth_ack{success:false,challenge}` → 对 challenge 原文 UTF-8 字节 `signPersonalMessage` → 发 `auth{address,paymentAddress,signature}` → 等 `auth_ack{success:true}`(30s 超时,challenge TTL 60s)→ provider_info + heartbeat。paymentAddress 缺省回退 address。
- 03:`web_socket_channel` + sealed 消息映射;心跳 15–20s(服务端 60s 硬断);重连指数退避 + full jitter;`query_settlement`/`_result`/`_error` 三条破坏 envelope 须特判;`provider_info.models` 只发 `relayModel`。

## Done looks like

一组钉死的装配决策(每项带理由 + 落点文件),足以让下一会话**直接照着写 `lib/core/node/` 代码**,不再有架构级分叉。
