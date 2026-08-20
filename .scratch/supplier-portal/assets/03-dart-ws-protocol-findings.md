# 资产 · 03 — 中转站 WS 协议 Dart 客户端可行性研究

> wayfinder research 资产,挂于 `issues/03-dart-ws-protocol-client.md`。基于 `web3-api` 的 TS 实现评估 Dart/Flutter 侧重写 WS 客户端的可行性与落地方案。所有结论附源码位置(文件:行号)。源码根目录 = `/Volumes/SHI-SSD/dev/web3-api`。

**结论先行:可行。** 协议是纯 JSON-over-WS,无二进制 frame、无压缩。唯一密码学依赖是 EIP-191 `personal_sign`(已由 01/10 解决)。`web_socket_channel` + 手写 sealed message 映射 + `Timer.periodic` 心跳即可覆盖全部功能。主要坑集中在:`query_settlement` 子协议破坏 envelope 一致性、challenge 是带特定空白布局的 SIWE 明文字符串、`provider_info.models` 字段名陷阱、服务端不主动踢旧连接、`web_socket_channel` 不暴露底层 socket(无 TCP keepalive)。

---

## A. 握手 / 鉴权时序

### A.1 精确握手序列

| 步 | 方向 | 消息 | 关键字段 | 源码 |
|---|---|---|---|---|
| 1 | client → relay | TCP/WS 连接 `relayWsUrl` | — | `client.ts:110` |
| 2 | relay → client | `auth_ack` | `{success:false, challenge:"<SIWE 字符串>"}` | `server.ts:131-132` |
| 3 | client 内部 | EIP-191 签名 `challenge` 字符串原文 | viem `signMessage({message, privateKey})` | `client.ts:217`, `siwe.ts:95-101` |
| 4 | client → relay | `auth` | `{type:"auth", payload:{address, paymentAddress, signature}}` | `client.ts:218-227` |
| 5 | relay 内部 | 校验:地址合法 → 未过期 → nonce 未重放 → EIP-191 verify | `verifyProviderAuth` | `auth.ts:126-180` |
| 6a | relay → client | `auth_ack` 成功 | `{success:true, challenge:<重生成>}` | `server.ts:479` |
| 6b | relay → client | `auth_ack` 失败 + `ws.close()` | `{success:false, error:"<reason>"}` | `server.ts:491-493` |
| 7 | client 内部 | `isConnected=true`,启动心跳,触发 `onAuthenticated` 回调 | — | `client.ts:187-194` |
| 8 | client → relay | `provider_info`(auth 成功后 **500ms** 延迟) | payload 见 A.5 | `client.ts:229`, `client.ts:237-300` |

### A.2 challenge 的真实性质

**challenge 是一段明文 UTF-8 字符串**,不是 hex、不是 base58。它是 SIWE-shaped(EIP-4361 子集),由服务端 `buildChallenge()` 拼接(`siwe.ts:74-81`):

```
<domain> wants you to sign in with your Ethereum account:
<address>


Nonce: <nonce>
Expiration Time: <iso>
```

**精确字节布局**(`siwe.ts:78-80`,Dart 侧不需要重建但必须理解其性质):

- `prefix = "<domain> wants you to sign in with your Ethereum account:\n<address>\n\n"`
- `suffix = "Nonce: <nonce>\nExpiration Time: <iso>"`
- `result = prefix + "\n" + suffix`  ← 地址与 Nonce 之间共有 **3 个 `\n`**(= 地址行尾 + 2 个空行)

**关键细节:**
- `address` 字段在 challenge 里是**服务端塞的占位 `zeroAddress`(`0x0000…0000`)**,不是供应商真实地址(`server.ts:124-125`,注释 `server.ts:62-67`)。签名时签的是占位地址版本;真实地址由 `verifyMessage` 从签名中恢复并与 `auth.payload.address` 比对(`auth.ts:153-176`)。**Dart 侧无需关心——直接签收到的字符串原文即可。**
- `domain`:默认 `"relay.example.com"`,可被 `RELAY_SIWE_DOMAIN` 环境变量覆盖(`server.ts:59`)。
- `nonce`:16 字节随机 → 每字节 `b % 62` 映射到 `[0-9a-zA-Z]`(`server.ts:503-514`)。≥8 字符 alphanumeric,符合 EIP-4361。
- `expiry`:UNIX 秒。`DEFAULT_CHALLENGE_TTL_SECONDS = 60`(`server.ts:52`),即 `connect 时刻 + 60s`。ISO 时间用 `new Date(unix*1000).toISOString()`(`siwe.ts:159-160`)。

### A.3 签名方式

`signMessage(privateKey, challengeString)` → viem `signMessage({message, privateKey})`(`siwe.ts:99-101`)。传入 **string 类型**(非 `{raw}`),viem 按 UTF-8 字节做 EIP-191:`\x19Ethereum Signed Message:\n<字节长度>` 前缀 + keccak256 + secp256k1。输出 65 字节 hex(`r||s||v`)。

**Dart 对应**:`eth_sig_util` 的 `personalSign`/`personal_sign`,对 challenge 字符串的 **UTF-8 codeUnits** 签名(personal_sign 规范是对字节计长度,非字符数——多字节字符会出错,但本协议 challenge 全 ASCII,无此问题)。互通性已由 [[01]]/[[10]] 实测确认。

### A.4 `auth` payload(client → relay)

```json
{
  "type": "auth",
  "payload": {
    "address": "<provider EIP-55 地址>",
    "paymentAddress": "<付款地址,缺省回退到 address>",
    "signature": "<0x 前缀 65 字节 hex>"
  }
}
```
源码:`messages.ts:16-20`,`client.ts:218-225`。`paymentAddress` 为空时 client 用 `address` 兜底(`client.ts:222`)。

### A.5 `provider_info` payload(client → relay,auth 成功后)

```json
{
  "type": "provider_info",
  "payload": {
    "address": "...",
    "paymentAddress": "...",
    "models": [
      { "relayModel": "<模型名>", "inputPricePer1k": <number>, "outputPricePer1k": <number> }
    ],
    "supportsStream": <boolean, 可选>
  }
}
```
源码:`messages.ts:75-80`。

> **字段名陷阱**:TS client 实际发送 `{name, relayModel, inputPricePer1k, outputPricePer1k}`(`client.ts:284-287`)——多了一个类型未声明的 `name` 字段。**服务端只读 `m.relayModel`**(`server.ts:394,403,413,430,438`),`name` 被完全忽略。**Dart 实现应只发 `relayModel`**,与 `messages.ts` 类型一致,避免冗余字段迷惑后续维护者。

### A.6 超时 / 重试约束(握手阶段)

- **challenge TTL = 60s**(`server.ts:52`)。client 从收到 challenge 到发 auth 必须在 60s 内完成;签名是本地计算,远低于此。
- **握手阶段无显式 client 端超时**——client.ts 不设 auth 超时,依赖底层 WS/TCP。建议 Dart 自行加一个 30–60s auth 超时主动重连。
- 握手失败(`success:false, error` 且无 challenge)→ client 主动 `ws.close()`(`client.ts:199-200`),触发重连链路。
- nonce **一次性**,重放会失败(`auth.ts:164-166`,`reason:"replayed"`)。每次连接服务端都发新 nonce,故重连安全。

---

## B. 完整消息目录

外层 envelope(绝大多数消息):`{type: string, payload: <对象>}`(`messages.ts:11-14`)。
`query_settlement` 子协议是**唯一例外**,见 C.3。

### B.1 出站(供应商 → 中转站)

| type | payload 字段 (名:类型:可选?) | 用途 | 源码 |
|---|---|---|---|
| `auth` | `address:string`, `paymentAddress:string`, `signature:string` | 握手签名应答 | `messages.ts:16-21` |
| `provider_info` | `address:string`, `paymentAddress:string`, `models:[{relayModel:string, inputPricePer1k:number, outputPricePer1k:number}]`, `supportsStream?:boolean` | 上报模型与报价 | `messages.ts:75-81` |
| `llm_response` | `requestId:string`, `response:LLMResponse`, `providerSignature:string`(当前恒为`""`) | 非流式推理结果 | `messages.ts:37-42`, `client.ts:356-360` |
| `llm_stream_chunk` | `requestId:string`, `chunk:LLMStreamChunk` | 流式增量 token | `messages.ts:44-48`, `client.ts:380-384` |
| `llm_stream_end` | `requestId:string`, `usage:LLMUsage`, `providerSignature:string`(当前恒为`""`) | 流式结束 + 计费 | `messages.ts:50-55`, `client.ts:412-416` |
| `llm_error` | `requestId:string`, `code:string`, `message:string` | 推理失败 | `messages.ts:57-62`, `client.ts:364-368` |
| `heartbeat` | `timestamp:number`(ms, `Date.now()`) | 应用层心跳 | `messages.ts:70-73`, `client.ts:443` |
| `query_provider_models` | `requestId:string`, `providerAddress:string` | 查某供应商在线模型 | `messages.ts:92-96`, `client.ts:478-483` |
| `query_model_params` | `requestId:string`, `q?:string` | 模糊查中转站模型库 | `messages.ts:98-102`, `client.ts:485-491` |
| `query_relay_records` | `requestId:string`, `provider:string`, `limit?:number`, `offset?:number`, `status?:string`, `chainStatus?:string` | 翻页查 relay 流水 | `messages.ts:104-112`, `client.ts:493-503` |
| `query_relay_records_by_tx_logindex` | `requestId:string`, `tx:string`, `logindex:number` | 按(tx,logindex)精查 | `messages.ts:130-138`, `client.ts:507-516` |
| `query_settlement` | **无 payload 包装**;顶层 `{type, tx:string}` | 查链上结算记录 | `messages.ts:169-172`, `client.ts:536` |

### B.2 入站(中转站 → 供应商)

| type | payload 字段 | 用途 | 溮码 |
|---|---|---|---|
| `auth_ack` | `success:boolean`, `error?:string`, `challenge?:string` | 握手 challenge 下发 / 鉴权结果 | `messages.ts:23-28` |
| `llm_request` | `requestId:string`, `request:LLMRequest`, `relaySignature:string` | 推理请求(含 `stream` 标志) | `messages.ts:30-35` |
| `llm_stream_cancel` | `requestId:string`, `reason:"client_disconnected"\|"timeout"\|"admin_kill"` | 取消在飞流 | `messages.ts:64-68`;发送方 `relay-server/src/http/llm.routes.ts:172,185` |
| `query_response` | `requestId:string`, `ok:boolean`, `data?:unknown`, `error?:string` | v1 查询通用回包 | `messages.ts:141-147` |
| `query_settlement_result` | **无 payload**;顶层 `{type, tx:string, records:QuerySettlementRecord[]}` | 链上结算成功回包 | `messages.ts:182-186` |
| `query_settlement_error` | **无 payload**;顶层 `{type, tx:string, reason:"not_found"\|"unauthorized"\|"internal"}` | 链上结算错误回包 | `messages.ts:188-194` |
| `heartbeat` | `timestamp:number` | 心跳应答(服务端原样回) | `server.ts:516-525` |

### B.3 类型目录里存在但**当前未使用**的消息

- **`registration_result`**(`messages.ts:83-88`):**全仓库无发送方**(grep 确认,仅在 messages.ts 定义)。服务端 `handleProviderInfo` 处理完 `provider_info` 后不发任何 ack(`server.ts:374-451`)。Dart 侧可定义该类型但不应期待收到。**这是"源码未体现实际使用"项。**
- **`providerSignature`** 字段:`llm_response`/`llm_stream_end` 里类型为 `string`,但 client.ts 当前恒发 `""`(`client.ts:346,402`)。原 Ed25519 非否认签名已删除,结算改为锚定 Polygon `Settled` 链上事件。Dart 侧发空串即可。

### B.4 LLM 载荷子结构(关键引用,非 WS 协议本身)

- **`LLMRequest`**(`types/llm.ts:1-36`):OpenAI Chat Completions 风格 + 透传字段(`[k:string]:unknown`)。关键标志 `stream:boolean?`。`messages: LLMMessage[]` 含 `role/content/tool_calls`。
- **`LLMResponse`**(`types/llm.ts:136-151`):`{id, object:"chat.completion", created, model, choices:LLMChoice[], usage:LLMUsage, ...}`。
- **`LLMStreamChunk`**(`types/llm.ts:153-161`):`{id, object:"chat.completion.chunk", created, model, choices:LLMStreamChoice[], ...}`,`delta: Partial<LLMMessage>`。
- **`LLMUsage`**(`types/llm.ts:115-126`):`{prompt_tokens, completion_tokens, total_tokens, prompt_tokens_details?, completion_tokens_details?, server_tool_use?, [k]:unknown}`。

> 这些 `[k:string]:unknown` 透传语义意味着 Dart 必须保留一个 `Map<String,dynamic>` 兜底字段,否则会丢厂商私有参数(Anthropic `thinking`、Gemini 字段、`stream_options.include_usage` 等)。

---

## C. 线路编解码

### C.1 编码格式

- **纯 JSON 文本帧**。`serializeMessage = JSON.stringify`,`deserializeMessage = JSON.parse`(`messages.ts:159-165`)。无压缩、无二进制、无 msgpack。
- 流式 token 走的也是文本 JSON(每 chunk 一条 `llm_stream_chunk` 消息,整条 JSON.stringify)。
- 解析失败时 client 仅 log 不中断(`client.ts:122-128`)。

### C.2 Envelope 结构

```json
{ "type": "<消息类型>", "payload": { ... } }
```
通用 envelope `WSMessage<T,P>`(`messages.ts:11-14`)。`type` 是 discriminated union(`messages.ts:3-9`,共 17 种字符串)。**Dart 反序列化策略:先解析外层 `type`,再按 type 分派到对应 payload 的 fromJson。**

### C.3 `query_settlement` 子协议的 envelope 破例

`query_settlement` / `query_settlement_result` / `query_settlement_error` **不走 `{type, payload}` envelope**,而是顶层平铺字段、且用 `tx` 而非 `requestId` 关联(`messages.ts:169-194`):

```json
{"type":"query_settlement","tx":"0x..."}                       // 出站
{"type":"query_settlement_result","tx":"0x...","records":[...]} // 入站
{"type":"query_settlement_error","tx":"0x...","reason":"not_found"} // 入站
```
这是后加的 v2 子协议(`messages.ts:167` 注释),**与 v1 envelope 不一致**。Dart 解析层必须对这三个 type 特殊处理,不能套通用 envelope 模板。`RelayWSMessage` 联合类型把它们和 `WSMessage<...>` 混在一起(`messages.ts:149-157`),TS 用 `unknown as` 强转绕过(`client.ts:159-163`)。

### C.4 ID 关联机制

| 业务 | 关联键 | 位置 |
|---|---|---|
| 推理(流/非流/错误/取消) | `payload.requestId`(string,由中转站生成,透传) | `client.ts:312`, `server.ts:528-549` |
| v1 查询(query_*→query_response) | `payload.requestId`(client 生成,格式 `q_<ms>_<rand8>`) | `client.ts:542`, `client.ts:590-603` |
| v2 链上结算查询 | **顶层 `tx`**(非 requestId) | `client.ts:523-539`, `messages.ts:169-194` |

> 流式响应的"关联"是在飞 `requestId` → 一系列 `llm_stream_chunk` + 一个 `llm_stream_end`/`llm_error`。同一个 requestId 的 chunk 顺序由 WS 帧顺序保证(无序列号)。

### C.5 `query_response.data` 的形状陷阱

v1 查询响应的 `data` 字段是 `unknown`(`messages.ts:144`),实际形状因查询类型而异(`client.ts:596-599`):
- `query_model_params` → `data` 直接是数组
- `query_relay_records` / `query_relay_records_by_tx_logindex` → `data` 是 `{records:[...]}` 对象
- `query_provider_models` → `{provider, isOnline, models:[...]}`

Dart 侧需按查询类型分别 cast。

---

## D. 心跳 / 超时 / 断连

### D.1 应用层心跳(双向,文本帧)

- **客户端发送间隔:30s**,消息 `{type:"heartbeat", payload:{timestamp:Date.now()}}`(`client.ts:441-446`)。
- **服务端收到后原样回一条 `heartbeat`**(`server.ts:516-525`),并 `updateHeartbeat(address)` 刷新 lastHeartbeat(`server.ts:519`)。
- 心跳用**应用层 JSON 消息**,不是 WS 原生 ping/pong control frame。

### D.2 服务端超时阈值

- 服务端每 **30s** 扫描连接池(`server.ts:166`),`now - lastHeartbeat > 60000`(**60s**)即 `provider.ws.terminate()` + 清池 + abort 该 provider 所有在飞流(`server.ts:167-175`)。
- 含义:client 若超过 60s 不发心跳就会被服务端单方面断开。client 当前 30s 间隔留有 30s 余量,但**单条心跳丢失即可能触发**——建议 Dart 侧把发送间隔压到 15–20s 更安全。

### D.3 Socket 层 keepalive(防御性)

双向都设了 TCP keepalive 兜底:`socket.setKeepAlive(true, 30_000)`(`client.ts:116`,`server.ts:115-116`)。注释说明 ws@8 不转发 socketOptions,故直接戳 `_socket`。**Dart `web_socket_channel` 不暴露底层 socket,无法设 TCP keepalive**——只能依赖应用层心跳(见 F 已知坑)。

### D.4 重连策略(现有 client.ts)

`scheduleReconnect`(`client.ts:455-461`):
- 初始 `reconnectDelay = 1000`ms,每次 `reconnectDelay * 2`,上限 `maxReconnectDelay = 60000`ms(`client.ts:83-84`)。
- 连接成功(`on("open")`)后 reset 回 1000(`client.ts:118`)。
- **无抖动(jitter)、无最大重试次数、无 full-jitter 优化**。
- 重连后**完整重走握手 + 重发 provider_info**(因为是全新 `connect()`,新 challenge,且 `onAuthenticated` 回调 + auth 后 500ms `sendProviderInfo` 会自动触发,`client.ts:229`)。
- 断开时清理:`stopHeartbeat` + `rejectAllPending`(所有在飞 query reject)+ `abortAllStreams`(abort 所有在飞 fetch),`client.ts:130-137`。

### D.5 服务端对同一地址重复连入的处理

**服务端不主动踢旧连接。** 新 WS 连接进来 → 新 challenge → 新 auth 成功 → `pool.updateByWs(newWs, address, ...)`(`server.ts:476`,`connection-pool.ts:55-81`)。`updateByWs` 把 `providers[address]` 整个替换成新 entry,但**不 close 旧的 ws**。旧 ws 何时清:仅当它自己触发 `on("close")`(`server.ts:148-158`)。

这意味着同地址双连期间,池里 `providers[address]` 指向新 ws,旧 ws 的 `byWs` 仍映射到 address 但其 entry 已被覆盖。这是个已知 race,代码注释大量讨论("治本 1",`connection-pool.ts:17-21,32-50`)。**Dart 侧无需特殊处理,但应避免同时维持两条连同一地址的 WS**(否则后建者会覆盖前者的池 entry)。

---

## E. 重连

(D.4 已覆盖核心)补充:

- **重连触发点**:仅在 `ws.on("close")`(`client.ts:130-136`)。`ws.on("error")` 只 log 不触发重连(`client.ts:139-141`)——但 `error` 后通常紧跟 `close`,故仍会重连。
- **`relayWsUrl = null` 时不连也不重连**:启动时若链上读失败,`connect()` 直接 return(`client.ts:101-107`),需重启进程才能重读。Dart 侧建议改成可重试链上读。
- **重连后的状态恢复**:provider_info 由 `onAuthenticated` 回调机制保证重发——`handleAuthAck` 成功时遍历回调(`client.ts:192-194`),且 `sendAuth` 内 `setTimeout(()=>sendProviderInfo(), 500)`(`client.ts:229`)。Dart 应在 auth 成功事件里同样触发报价重发。
- **在飞请求处理**:重连不等同于恢复——所有在飞 query 被 reject、所有在飞 stream 被 abort(`client.ts:177-182`,`client.ts:623-634`)。中转站侧对应流的清理由 `abortStreamsForProvider`(`server.ts:90-101`)在 provider 断线时 emit `provider_disconnected` 错误给上游客户端。**不保证 at-least-once**,Dart 侧需要上层决定是否对终端用户重试推理。

---

## F. Dart 实现方案与已知坑

### F.1 `web_socket_channel` 对接时序

```dart
final channel = WebSocketChannel.connect(Uri.parse('ws://relay:3003'));
// 发送
channel.sink.add(jsonEncode(msg.toJson()));
// 接收
await for (final raw in channel.stream) {
  final json = jsonDecode(raw as String) as Map<String, dynamic>;
  _dispatch(json);
}
// 关闭
await channel.sink.close();
```
- `WebSocketChannel.connect` 立即开始握手;连接建立后服务端会**主动**推 `auth_ack(success:false, challenge)`,所以 Dart 一接进 stream 就要先处理入站,无需先发任何东西。
- `channel.stream` 是单订阅流——用一个 `await for` 循环集中分发,不要多处 listen。
- `channel.sink.add` 是非阻塞的;流式回包时注意背压(见 F.5)。

### F.2 消息编解码建议:sealed class + type 分派

不要全量上 codegen。协议只有 17 个 type,且 `query_settlement` 破坏 envelope 一致性,手写更显式。骨架:

```dart
sealed class RelayMessage {
  const RelayMessage();
  factory RelayMessage.fromJson(Map<String, dynamic> j) {
    final type = j['type'] as String;
    // query_settlement 子协议:无 payload,顶层平铺
    switch (type) {
      case 'query_settlement_result':
        return QuerySettlementResult.fromJson(j);
      case 'query_settlement_error':
        return QuerySettlementError.fromJson(j);
    }
    // 通用 envelope
    final p = (j['payload'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    return switch (type) {
      'auth_ack'          => AuthAck.fromJson(p),
      'llm_request'       => LlmRequestMsg.fromJson(p),
      'llm_stream_cancel' => LlmStreamCancel.fromJson(p),
      'query_response'    => QueryResponse.fromJson(p),
      'heartbeat'         => Heartbeat.fromJson(p),
      _ => throw FormatException('unknown ws type: $type'),
    };
  }
  Map<String, dynamic> toJson();
}
```

- type→class 映射全表:`auth`/`auth_ack`/`llm_request`/`llm_response`/`llm_stream_chunk`/`llm_stream_end`/`llm_stream_cancel`/`llm_error`/`heartbeat`/`provider_info`/`query_provider_models`/`query_model_params`/`query_relay_records`/`query_relay_records_by_tx_logindex`/`query_response` 走通用 envelope;`query_settlement`/`query_settlement_result`/`query_settlement_error` 走顶层平铺特例。
- `registration_result` 类型可定义但不要在 `fromJson` 里期待(B.3 已述当前无发送方)。
- **LLM 子结构保留透传字段**:`LLMRequest.fromJson` 必须把未知 key 收进 `Map<String,dynamic> extra`,否则丢厂商私有参数。用 `freezed` + `@JsonSerializable(extra: ...)` 或手写。

### F.3 心跳:`Timer.periodic` + 应用层消息

```dart
Timer? _hb;
void _startHeartbeat() {
  _hb?.cancel();
  _hb = Timer.periodic(const Duration(seconds: 30), (_) {
    _send({'type':'heartbeat','payload':{'timestamp': DateTime.now().millisecondsSinceEpoch}});
  });
}
```
- 用应用层 `heartbeat` 消息,**不要**尝试用 WS 原生 ping(`web_socket_channel` 不暴露)。
- 建议间隔 **15–20s**(比 TS 的 30s 更激进),因为服务端 60s 硬超时,单帧丢失余量更大。
- 服务端回的心跳在分发器里静默忽略即可(无需 ack 处理)。

### F.4 重连策略建议

- **指数退避 + full jitter**:`delay = random(0, min(cap, base * 2^attempt))`,base=1s,cap=60s(与现有一致但加抖动避免惊群)。
- **重连即重握手**:每次 `WebSocketChannel.connect` 都从头走 auth_ack→auth→provider_info。
- **主动 auth 超时**:连接后 30s 内未收到 `auth_ack(success:true)` 主动 close 重连(TS 没做,依赖底层)。
- **`relayWsUrl` 重读**:TS 在启动时读链上 PDA 得 URL,失败即永久放弃(`client.ts:101-107`)。Dart 建议把链上 URL 解析包成可重试的 future,重连链路里定期重读,避免一次 RPC 抖动导致永久离线。
- **单连接约束**:同一地址同一时刻只维持一条 WS(见 D.5)。

### F.5 已知坑清单(按踩坑概率排序)

1. **`query_settlement` 三条消息破坏 envelope**:Dart 解析层若一刀切假设 `{type, payload}`,会在这三条上 crash。必须在 `fromJson` 入口先拦截(F.2 骨架已含)。关联键是 `tx` 不是 `requestId`,pending map 也要单独维护(TS 用了独立的 `pendingSettlementQueries` map,`client.ts:90`)。

2. **`provider_info.models` 字段名**:服务端只读 `relayModel`,TS 多发的 `name` 被丢。Dart 只发 `relayModel`。报价数值是 `number`(JSON 实数),nUSD 单位(公式 `round((in*tok_in + out*tok_out)/1000)`,`client.ts:339,394`)——Dart 侧注意用 `num` 接收避免 int 截断。

3. **challenge 是明文 SIWE 字符串,含精确空白**:虽然 Dart 只需签收到的字符串原文,但若调试时自行重建 challenge(例如做互通测试),必须精确复制 `prefix + "\n" + suffix` 的布局(地址后 3 个 `\n`)。少一个 `\n` 签名就对不上。

4. **`web_socket_channel` 不暴露 TCP keepalive / ping**:无法复现 `socket.setKeepAlive(true, 30000)`。唯一防线是应用层心跳——必须确保心跳 timer 在 app 进入后台时仍触发(Flutter 需 `workmanager` 或保持前台 service,否则 iOS 后台会挂起 timer,导致服务端 60s 后踢连接)。**这是 Dart 侧最大的行为差异**,直接关联 Fog 里的"移动端后台保活策略"。

5. **challenge address 是 `zeroAddress` 占位**:签名时签的是占位地址版本,不是真实地址。若 Dart 侧误把真实地址拼进 challenge 自行重建并签名,校验必失败。**解决:永远只签服务端发来的 challenge 字符串,不重建。**

6. **流式背压**:`web_socket_channel.sink.add` 不阻塞,但底层有缓冲。若上游 LLM 流式 chunk 比服务端消费快(很少见,因服务端是 emit 给 SSE 订阅者),可能堆积。TS 侧用 fetch stream + AbortController(`client.ts:374-428`)。Dart 侧建议用 `StreamController` 做中间缓冲 + `sync:false`,并在 sink close 时 abort 上游 HTTP。

7. **大 JSON 消息**:`llm_request` 可能含长 prompt + tools 定义,单条 JSON 可能数十 KB 到几 MB。`jsonDecode` 默认 OK,但若用 `dart:convert` 一次性解析超大消息会阻塞 isolate——建议大消息用 `utf8.decoder + JsonDecoder` 流式解析。当前协议未设大小上限,服务端 `ws.on("message")` 无 maxPayload 检查(`server.ts:138-146`)。

8. **`llm_stream_cancel` 入站方向陷阱**:在 messages.ts 它和 `llm_stream_chunk`/`llm_stream_end` 同属一个方向枚举,但实际**入站**(中转站→供应商,发送方在 `relay-server/src/http/llm.routes.ts`)。出站的流消息是 chunk/end/error。Dart dispatch 时不要把 `llm_stream_cancel` 误归到出站处理器。

9. **`query_*` 的方向陷阱**:`query_provider_models` 等对**供应商**是出站请求 + 入站 `query_response`;但要注意 `query_provider_models` 在中转站侧也是从**其他查询方**(admin/用户)入站的消息类型。Dart 客户端角色固定为"供应商",故这些 type 全部按"出站请求"处理,回包统一走 `query_response`。

10. **`providerSignature` 当前恒空串**:不要花时间在 Dart 实现签名生成。`llm_response`/`llm_stream_end` 的 `providerSignature` 发 `""` 即可(`client.ts:346,402`)。结算锚定链上事件,非链下签名。

11. **nonce 单次性 + challenge 60s TTL**:每次 WS 连接 nonce 不同,签名只对当次有效。不要缓存签名重发。重连必走新握手。

12. **JSON 解析容错**:服务端可能下发未知 type(协议演进)。TS 用 `as RelayWSMessage` 强转 + switch 落空(`client.ts:144-167`,default 不处理)。Dart `switch` 应有 `_ => log-and-ignore` 兜底,不要抛异常断 stream。

13. **`paymentAddress` 兜底**:`client.ts:222` 中 `getPaymentAddress() || getProviderAddress()`。Dart 侧若 paymentAddress 为空字符串/null,回退到 provider address,否则服务端 `pool.updateByWs` 会存空(`server.ts:476`),影响后续结算地址。

---

## 附录:可行性判定

| 维度 | 判定 | 备注 |
|---|---|---|
| 协议复杂度 | 低 | 纯 JSON,17 type,无二进制 |
| 密码学依赖 | **已解决**(前提) | EIP-191 personal_sign,01/10 确认 Dart 互通 |
| WS 库能力 | 充分 | `web_socket_channel` 支持文本帧双向;唯缺 TCP keepalive |
| 心跳/重连 | 需自实现 | TS 用 `setInterval`/`setTimeout`,Dart 用 `Timer` 等价 |
| 流式支持 | 需自实现 | TS 用 fetch+AbortController,Dart 用 `http`/`dio` stream |
| 主要风险 | 后台心跳 | Flutter 后台 timer 挂起 → 服务端 60s 踢连接(F.5 #4) |

**结论:可行,建议推进。** 落地优先级:先握手+auth+provider_info 跑通 → 加心跳+重连 → 接入 llm_request 非流式 → 流式 → query 系列 → query_settlement(最后,因为 envelope 特例多)。真实握手联调(对真实中转站冒烟)属 04 的 scope。

---

## 关键源码引用索引(全部绝对路径)

- `/Volumes/SHI-SSD/dev/web3-api/packages/shared/src/protocol/messages.ts` — 协议权威,消息目录 + envelope
- `/Volumes/SHI-SSD/dev/web3-api/packages/shared/src/crypto/siwe.ts` — challenge 构造 + EIP-191 sign/verify(`buildChallenge` `siwe.ts:74`,`signMessage` `siwe.ts:95`,`verifyMessage` `siwe.ts:118`)
- `/Volumes/SHI-SSD/dev/web3-api/packages/provider-server/src/ws/client.ts` — 现有 TS 客户端(被替换的参考)
- `/Volumes/SHI-SSD/dev/web3-api/packages/relay-server/src/ws/server.ts` — 中转站服务端,握手 + 心跳超时(`setupWebSocket` `server.ts:103`,心跳扫描 `server.ts:166-176`)
- `/Volumes/SHI-SSD/dev/web3-api/packages/relay-server/src/ws/auth.ts` — 鉴权四道闸门(`verifyProviderAuth` `auth.ts:126`)
- `/Volumes/SHI-SSD/dev/web3-api/packages/relay-server/src/ws/connection-pool.ts` — 连接池 / placeholder race / 重入处理
- `/Volumes/SHI-SSD/dev/web3-api/packages/shared/src/types/llm.ts` — LLM 载荷子结构(含透传字段语义)
- `/Volumes/SHI-SSD/dev/web3-api/packages/relay-server/src/http/llm.routes.ts:172,185` — `llm_stream_cancel` 的真实发送方(证明其入站方向)
