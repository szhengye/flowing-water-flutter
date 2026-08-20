# CONTEXT.md — 流水·供应商端 (flowing-water-flutter)

> 本仓的领域语言(ubiquitous language),从**供应商端**视角写。实现决策见 `docs/adr/`(暂无,按需建)。上游权威定义见 `../web3-api/CONTEXT.md`,冲突时以上游为准。

## Project

「流水·供应商端」是一个 Flutter 多端应用(macOS / Windows / iOS / Android),**取代** web3-api 中的 `provider-server`(Node.js 供应商后台)+ `provider-portal`(Next.js 供应商门户)。它作为一个**供应商节点**,通过 WebSocket 连到「中转站」(已实现的 `relay-server`,不改),把中转站转发来的 LLM 请求再转发给上游 LLM 厂商,并按 Polygon 链上 `Settled` 事件对账收取 USDT;GUI 同时提供原 provider-portal 的全部管理能力。

定位:供应商(运营自己算力的人)的"运营商门户"客户端。**一个 app 实例 = 一个供应商身份**(单 keypair / 单地址 / 一条 WS 连接)。

## 角色三角(承自上游)

- **接入商** Customer — 持 `sk-relay-*` API key 的终端用户,调中转站的 OpenAI 兼容 API。本仓不直接打交道。
- **中转站** Relay — `relay-server`,经纪转发 + 链上批量结算。**本仓的连接对端**(WS `:3003`)。已实现,不改。
- **供应商** Vendor / Provider — 算力提供方。**本仓扮演的就是这个角色。**

## Ubiquitous language

- **供应商节点 / Provider 节点** — 本 app 扮演的 always-on 角色:维持到中转站的 WS 长连,路由 `llm_request`,转发给上游,回传流式 chunk。**桌面端为真正常驻节点**;移动端后台保活受限,仅前台尽力而为。
- **WS / WebSocket** — 供应商→中转站的长连,SIWE 形态质询 + EIP-191 `personal_sign` 鉴权。协议消息权威:`../web3-api/packages/shared/src/protocol/messages.ts`。
- **Forwarder / Adapter** — 把中转站统一 `LLMRequest` 翻成某上游厂商原生 HTTP、再把流式响应翻回统一 chunk 的适配层。5 个 adapter:OpenAI / Anthropic / Gemini / DeepSeek / Azure OpenAI。
- **provider_info** — 鉴权后供应商上报给中转站的信息:可用模型清单 + 每 1k token 报价 + 是否支持流式。
- **Settled 事件** — 链上 `RelayStationPolygon.settle(...)` 逐供应商发出的事件;本 app 监听属于自己的事件,与本地调用记录对账,确认应收 USDT。
- **Keypair / Mnemonic** — 供应商的 secp256k1 keypair,由 12 词 BIP-39 助记词派生。注册时生成、只展示一次、本地 AES-256-GCM 加密存储、解密载入内存。地址用于鉴权与收款。
- **provider_log / provider_chain_settlement** — 上游 provider-server 的 SQLite 表:本地 LLM 调用记录 / 链上结算记录。本仓需等价持久化。
- **operator(中转站操作员)** — 上游术语,指持中转站 operator 私钥、唯一能调 `settle()` 的 Polygon EOA。**不是本 app 的用户**(本 app 用户是供应商)。注意区分,勿混。

## 关键约束(已定,详见 `.scratch/supplier-portal/map.md`)

- 完全替换 Node.js provider-server(不共存——同一供应商地址只能一条 WS 连中转站)。
- 全平台内嵌完整 provider 逻辑;移动尽力而为,桌面才是真常驻节点。
- 视觉:借 `../listening-king` 的架构模式(token 体系 / service 单例 / desktop scaffold / provider-as-stream-bridge),自定专业供应商后台风,不照搬 Duolingo 活泼风。
- 借鉴参考:`../listening-king`(Flutter 多端架构)、`../web3-api`(被取代的上游实现 + 协议权威)。
