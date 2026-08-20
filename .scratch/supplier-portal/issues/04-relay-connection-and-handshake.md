# 04 — 确认中转站部署 + Dart WS 握手冒烟

Type: task
Status: resolved

## Question

中转站(relay-server)是否已部署运行?WS 端点地址(`:3003`,或链上 `wsUrl` 指向的地址)是多少?用它 + 一个测试供应商 keypair(用 01 的方案生成),在 Dart 里跑通**一次完整 WS 握手**(连上 → 收 challenge → 签名 → `auth_ack` success)作为全链路可行性冒烟。

## Context

- relay-server 三端口:`:5080`(OpenAI 兼容 LLM API)/ `:3000`(admin REST)/ `:3003`(WS,供应商连)。
- 部署文档:`../web3-api/docs`(manual-relay-deploy);Polygon 上 `wsUrl` 是链上查到的中转站 WS 地址。
- 中转站由链上合约的 `wsUrl` 决定(CONTEXT.md)。

## Done looks like

记录:中转站 WS URL + 可达性 + 一次成功握手的关键日志(或失败原因)。这是后续所有真实联调的前提。手工 / 运维 + 冒烟,不是决策;完成后把结论(facts)挂本 ticket。

## Answer

**结论:全链路握手冒烟通过 ✅** —— 本地 dev relay(空合约、未加载 operator keypair)即可完成。

### 环境(facts)
- relay:`../web3-api/packages/relay-server`,dev 裸机启动,WS **`ws://localhost:3003`**(`RELAY_WS_PORT=3003`)。
- `.env`:`ADMIN_API_KEY=dev-smoke-key`;`POLYGON_CONTRACT_ADDRESS=0x0…0`(空 → 跳过链上调用,只起本地业务 + WS);Amoy 公共 RPC。
- **关键:无需部署合约、无需 operator 助记词**即可握手——SIWE challenge + EIP-191 验签与链无关。

### 握手结果(spike `spikes/ws-handshake/dart-spike`)
随机生成测试供应商 keypair(mnemonic → `m/44'/60'/0'/0/0` → `0x9728Ea1418De1c97AB77F19EFd20709fcC586892`),完整握手:
1. 连 `ws://localhost:3003` → relay 主动推 `auth_ack{success:false, challenge}`(177 字符 SIWE 明文;domain `relay.example.com`、地址占位 `0x0…0`、Nonce + Expiration,布局与 03 findings §A.2 逐字节一致)。
2. Dart 对 challenge 原文做 EIP-191 `personal_sign`(`eth_sig_util`),发 `auth{address(EIP-55), paymentAddress, signature}`。
3. **relay 返回 `auth_ack{success:true}`** —— viem `verifyMessage` 接受了 Dart 签名(crypto 互通 01/10 在真实 relay 上交叉验证)。
4. post-auth:`provider_info`(relay log `reported 1 models (stream=true)`)+ `heartbeat`,收到 **heartbeat 回包**(双向通道确认)。退出码 0。

### 服务端佐证(relay log)
```
WebSocket listening on port 3003
[ws] New connection, nonce: mqWCqbCfiKmXOK4V, challenge: relay.example.co...
[auth] received auth from 0x9728…86892, challenge in map: yes
Provider authenticated: 0x9728…86892
[ws] message type: provider_info → Provider … reported 1 models (prev had 0, stream=true)
[ws] message type: heartbeat
Provider disconnected: 0x9728…86892
```

### 噪声(预期,非问题)
- `[settlement-watcher] scan error: RPC Request failed` —— 空合约下 watcher 扫 `Settled` 事件命中公共 Amoy RPC 偶发错误;结算不在本次范围,部署真实合约后消失。
- `health` 末态 `providers:0` —— spike 是一次性冒烟,握手后即断开;连接期间 provider 已注册(见服务端 log),断开后归 0 属正常。

### 复现
- spike:`spikes/ws-handshake/dart-spike`(`dart pub get && dart run bin/handshake.dart ws://localhost:3003`)。
- relay 启动 runbook:`spikes/ws-handshake/RELAY-STARTUP.md`(install + 仅 build shared/relay-server + 最小 .env + `node dist/index.js`)。

### 对 map 的影响
- 真实联调前提已满足;05(架构)/ 09(forwarder)实现均可在本地 relay 集成验证。
- 「迁移割接与行为对齐验证」Fog 获强实证:WS 兼容 + crypto 互通在真实链路成立(剩余:llm 往返、结算对账)。
- 新增 ticket 11(端到端 LLM 往返冒烟),`Blocked by: 05, 09`。
