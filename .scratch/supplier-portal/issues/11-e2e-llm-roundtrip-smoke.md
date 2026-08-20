# 11 — 端到端 LLM 往返冒烟(对真实 relay)

Type: task
Blocked by: 05, 09
Status: resolved

## Question

04 已证明 Dart provider 能对本地 relay 完成 connect → auth → provider_info → 心跳。本 ticket 把链路推到下一站:**一次真实 LLM 推理往返**。

Dart provider(已 auth)收到 relay 转发的 `llm_request`(`stream=true`),经 forwarder adapter(09 选型)转发到某真实上游 LLM(如 OpenAI / DeepSeek),把流式响应翻成 `llm_stream_chunk` + `llm_stream_end`(含 `usage`),relay 回传接入方;本地 `provider_log` 记一条调用记录。

## Done looks like

- 接入方发 `/v1/chat/completions`(stream)→ relay → Dart provider → 真实上游 → 流式回包,**端到端可见**。
- 本地记录与 relay 侧记录可对账(token 用量一致)。
- 记录:用了哪个 adapter / 模型 / 上游 key 来源 + 关键日志 + 任何协议层偏差(chunk 序、`usage` 字段、`providerSignature` 恒空串、透传字段是否丢失)。

## Context

- 依赖 05(应用架构:provider_info 上报、`llm_request` dispatch、stream 缓冲在哪层)与 09(forwarder adapter 选型与接口)。
- 需要一个真实 LLM API key(task 性质:需人提供 / 配置)。
- 协议时序见 03 findings §B/C;LLM 载荷子结构见 §B.4(注意透传字段 + `providerSignature` 恒空串)。
- 本地 relay 已可起(runbook `spikes/ws-handshake/RELAY-STARTUP.md`);接接入方需 relay 的 OpenAI 端口 `:5080` + 一个 `sk-relay-*` API key(relay admin 侧创建)。

## Answer

**结论:端到端流式往返打通,本地记录与 relay 侧记录可对账(token 用量一致)。**

### 跑的是什么(脚本)

新建 `spikes/ws-handshake/dart-spike/bin/e2e_llm.dart`(复用 04 握手 + 镜像 09 的 openai adapter + 内存 sqlite provider_log)。`dart analyze` 干净。运行:

```
UPSTREAM_BASE_URL=https://token.sensenova.cn \
UPSTREAM_API_KEY=<不落盘,环境变量传入> \
UPSTREAM_MODEL=sensenova-6.7-flash-lite \
dart run bin/e2e_llm.dart
```

另开终端,接入方用 sk-relay key 打 relay `:5080`:

```
curl -N http://localhost:5080/v1/chat/completions \
  -H 'Authorization: Bearer sk-relay-...' -H 'Content-Type: application/json' \
  -d '{"model":"gpt-4o-mini-smoke","stream":true,"messages":[{"role":"user","content":"说三个字"}]}'
```

### adapter / 模型 / 上游 key 来源

- **adapter**:openai(09 选型,mirror web3-api `forwarder/adapters/openai.ts` — resolveEndpoint / buildRequest / parseStreamLine 三方法)。
- **上游**:SenseNova,OpenAI 兼容协议。endpoint `https://token.sensenova.cn`(resolveEndpoint 补 `/v1/chat/completions`),model `sensenova-6.7-flash-lite`。
- **key 来源**:环境变量 `UPSTREAM_API_KEY`。脚本启动时校验,不落盘、不进 repo、不硬编码。**与 Claude Code 自身的 ANTHROPIC_* 凭据完全无关。**
- relayModel(上报给 relay / 接入方按此请求):`gpt-4o-mini-smoke`。relay 据此 selectProvider;脚本收到 llm_request 后把 model 改写成上游真实模型 `sensenova-6.7-flash-lite`。

### 端到端时序(实测)

接入方 curl → relay `:5080` → relay 选 provider、插 pending relay_log、WS `llm_request{requestId, request, relaySignature:""}` → Dart provider:
1. 收 llm_request,本地插 pending provider_log(in=1/out=2 价)。
2. dio POST 上游(stream,强制 `stream_options.include_usage:true`)。
3. 校验 Content-Type 含 `text/event-stream`(SenseNova 实测通过)。
4. 逐行 SSE 解析:每 chunk → `llm_stream_chunk{requestId, chunk}` × N;末行 `choices:[]`+`usage` 抽 usage;`data: [DONE]` → done。
5. `llm_stream_end{requestId, usage, providerSignature:""}` → relay → SSE `data: …\n\n`…`data: [DONE]\n\n` 给接入方。
6. 收尾 `completeRecord`(completed)→ `query_relay_records` 拉 relay 侧记录对账。

### 对账(关键日志,真实跑出来的 requestId=38f8abfb…)

| 字段 | 本地 provider_log | relay 侧 relay_log |
|---|---|---|
| input_tokens | 12 | 12 |
| output_tokens | 681 | 681 |
| amount(nUSD) | 1 | 1 |
| processing_status | completed | completed |
| latency_ms | 6067 | 6071(差 ~4ms,relay 计的是 relay↔provider 全程) |

**token 用量一致 ✅,amount 一致 ✅,对账通过。**

### 协议层偏差(需记)

1. **`providerSignature` 恒空串** ✅ — `llm_stream_end` 里固定 `""`,与 03 锁定一致(Ed25519 非抵赖已移除,链上 Settled 锚定)。relay 侧 `provider_signature` 也是 `""`。
2. **`relaySignature` 恒空串** ✅ — `llm_request.payload.relaySignature` 收到即 `""`。
3. **上游 chunk 含非标准 `reasoning` 字段** — SenseNova 流里 delta 带 `reasoning`(思考链),openai adapter 的 "spread delta verbatim + 保留顶层非标准字段" 设计原样透传给接入方,**未丢失**。接入方 SSE 里可见 `"reasoning":"..."`(P0~P3 透传验证通过)。
4. **`role` 字段为 null** — SenseNova 首包 delta 无 role,adapter 输出 `"role":null`(不是 undefined/缺省)。接入方若按 OpenAI 严格 schema 校验需注意,但协议层不丢字段。
5. **usage 在末尾独立 chunk**(`choices:[]`)— adapter 正确识别并抽 usage,`usageReported=true`,无 silent-billing-risk。
6. **非流式未支持** — spike 聚焦 stream(ticket 11 Done: stream);非流式返回 `SPIKE_NON_STREAM_UNSUPPORTED`(明确报错,非静默)。
7. **首次长答案往返曾触发 relay 侧 `client_disconnected`** — 接入方 curl `-m 90` + 上游长 reasoning(1496 tokens)导致接入方先断,relay 把该 requestId 标 `failed/client_disconnected`,而 provider 侧仍跑完标 completed。**这是接入方超时与上游慢的时序问题,非协议层 bug**:缩短 prompt / 接入方去掉超时即可(后续短 prompt 轮次无此现象)。provider 侧 amount/usage 仍正确记录,可据此做 provider 侧结算;relay 侧因 client 断开未计入 customer credits。

### 踩过的坑(实现细节)

- `dart analyze` 4 处:`??` vs `>` 优先级(usage 判空需加括号)、`ev.done` 是 `bool?` 需 `== true`、`_StreamEvent.error` 参数改 catch 内回填而非返回 null。
- **完成时序**:初版用固定 `Future.delayed(2s/3s)` 等往返完成,被长答案(15s)穿透导致 main 提前退出、WS 断、relay 标 `provider_disconnected`。改为 `Completer roundDone`:`_handleLlmRequest` 跑完(含对账)再 complete,main 阻塞其上,给 120s 上限。修复后短/长答案均稳定。

### 资产

- 脚本:`spikes/ws-handshake/dart-spike/bin/e2e_llm.dart`(`dart analyze` 干净)。
- 依赖:pubspec 加 `dio ^5.7.0`、`sqlite3 ^2.4.0`。
- 上游 key:**不入 repo**。运行时经 `UPSTREAM_API_KEY` 传入。

