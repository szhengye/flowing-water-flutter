# 09 — Forwarder / Adapter 架构

Type: grilling
Blocked by: 03
Status: resolved (2026-08-08, supplier-portal session)

## Question

5 个 LLM adapter 的**流式转发管线**在 Dart 怎么设计?

- 输入 = 中转站统一 `LLMRequest`(经 03 的 WS 路由进来)。
- 每 adapter 翻成厂商原生 HTTP(OpenAI / Anthropic / Gemini / DeepSeek / Azure),解析流式响应 → `llm_stream_chunk`(多条)→ `llm_stream_end`(带 `usage` + `providerSignature`)。
- 处理 `llm_stream_cancel`(中转站取消)。
- Dart 流式 HTTP(dio / http)+ 上游 SSE 解析;adapter 抽象(统一接口 + 每厂实现)。

## Context

- 上游:`../web3-api/packages/provider-server/src/forwarder/adapters/`(5 个 adapter)+ forwarder 路由。
- 协议:`web3-api/packages/shared/src/protocol/messages.ts`(`LLMRequest` / `LLMStreamChunk` / `LLMUsage` 形状)。
- 依赖 03(WS 消息进出)。注:`providerSignature` 恒为 `""`(见 [01 结论](01-dart-crypto-feasibility.md)),forwarder **无需签名**,只填空串。

## Done looks like

forwarder 架构设计(adapter 抽象 + 流式管线 + 取消语义)+ 与 03 WS 层的接口契约。用 /grilling 或 /prototype 出草图。

## Answer

经对上游 `provider-server/src/forwarder/`(5 adapter + 路由 + WS 粘合)的逐行研究,定 Dart 侧 forwarder 架构。**镜像上游接口形状(`buildRequest`/`parseResponse`/`parseStreamLine` 三方法 + 5 适配器工厂),不改协议、不镀金**;差异只在语言机制(dio 替 fetch、`CancelToken` 替 `AbortController`)与上游已定决策(`providerSignature` 恒 `""`)。本 ticket 只定**架构与契约**,不写实现代码(留给下游实现 ticket / 11 联调)。

### 1. 定位与边界

- 落 `lib/core/forwarder/`(05 已定),与 `core/ws/` 的 `RelayClient`(03)在**主 isolate 内**通过 Riverpod provider 接入(05:节点跑主 isolate,重活 `compute()` 卸载)。
- **职责切分**:`RelayClient` 只管 WS 收发(envelope/鉴权/心跳,03);`Forwarder` 只管 `llm_request` → 上游 HTTP → 流式回包。两者通过 **`StreamDispatcher`** 桥接:WS 侧把 `llm_request` 交给 dispatcher,dispatcher 经 provider 注入的 `Forwarder` 发起转发,把 chunk/end/error 回吐给 `RelayClient` 发回中转站。
- **不进 forwarder**:provider_log 持久化(06 的 drift 层)在 dispatcher 层调用(转发前后插桩),forwarder 本身只产流事件、不碰 DB。与上游一致(WS client 调 `insertRecord/completeRecord`,forwarder 只产 callback)。

### 2. 适配器抽象(`core/forwarder/adapters/`)

镜像上游 `ProviderAdapter` 接口,三方法 + 每厂实现:

```dart
/// 镜像上游 AdapterType;与 provider_info.adapter_type 字段对齐(06 schema)。
enum AdapterType { openai, anthropic, gemini, deepseek, azureOpenai }

class AdapterRequest {
  final Uri url;
  final Map<String, String> headers;
  final String body; // JSON 串,UTF-8
  const AdapterRequest(this.url, this.headers, this.body);
}

/// 上游 SSE 逐行解析的统一产物(对应上游 AdapterStreamEvent)。
sealed class StreamEvent {}
class ChunkEvent extends StreamEvent { final LLMStreamChunk chunk; }
class UsageEvent extends StreamEvent { final LLMUsage usage; }
class DoneEvent  extends StreamEvent {}
class ErrorEvent extends StreamEvent { final String message; }

abstract class ProviderAdapter {
  AdapterType get type;
  AdapterRequest buildRequest({
    required String providerEndpoint,
    required String providerApiKey,
    required String providerModel,
    required LLMRequest request,
    required bool stream,
  });
  LLMResponse parseResponse(Object json, String providerModel); // 非流式(低频,但保留对齐上游)
  StreamEvent? parseStreamLine(String line, String providerModel);
}
```

- **关键:逐调用新建实例**(同上游 `getAdapter` 工厂)。**Anthropic adapter 带 per-stream 状态**(`openToolUses: Map<int,({String id, String name})>`,索引 `content_block_start` 的 tool_use 块)——共享实例会让并发流的 tool_use 块索引串台。工厂 `ProviderAdapter.forType(AdapterType)` 每次返回新实例。
- **DeepSeek / Azure 复用 OpenAI**:`DeepSeekAdapter` 精简委托 `OpenAIAdapter`(同协议,只 endpoint 不同);`AzureOpenAIAdapter` 委托 `OpenAIAdapter` 的 `parseResponse`/`parseStreamLine`,仅覆写 `buildRequest`(部署 URL `{base}/openai/deployments/{model}/chat/completions?api-version=...` + `api-key` header,默认 api-version `2024-02-15-preview`)。与上游一一对应,Rule 11。

### 3. 逐厂解析要点(从上游逐行核对,移植到 Dart)

| adapter | 厂商原生形状 | Dart 解析要点 |
|---|---|---|
| **OpenAI** | `/v1/chat/completions` SSE,data 行 `choices[].delta` + 末尾 `usage`(需 `stream_options.include_usage=true`) | `resolveEndpoint` 自动补 `/chat/completions`;流式注入 `stream_options`;逐行 JSON,`data: [DONE]` → done。DeepSeek 同。 |
| **Anthropic** | `/v1/messages` SSE,event 名区分(`message_start`/`content_block_start`/`content_block_delta`/`message_delta`/`message_stop`) | 顶层 system 字符串抽离;`max_tokens` 默认 4096;header `x-api-key`+`anthropic-version: 2023-06-01`;**带 per-stream `openToolUses` 状态**追 tool_use 块;`message_delta` 携 `output_tokens`;`stop_reason`→`finish_reason` 映射。 |
| **Gemini** | `?key=` URL 参数;原始 **JSON 流**(非 SSE,逐行 `[{...},{...}]` 增量对象) | `systemInstruction`;角色映射(`assistant`→`model`、`tool`→`function`、带 tool_calls 的 assistant→`functionCall` 部分);`generationConfig`;`usageMetadata`(prompt/candidates/totalTokenCount)。**非 SSE**,解析器须区分。 |
| **Azure** | 部署 URL + `api-key` header | 委托 OpenAI 解析。 |

> 透传:`LLMRequest` 有 `[k:string]:unknown` 透传字段(上游协议);adapter 构 body 时**上游优先级扩展**(已知字段映射到厂商原生,未知字段透传进 body),解析侧反之。Rule 11:与上游一致,不擅自裁剪。

### 4. 流式管线(`core/forwarder/forwarder.dart`)

`dio`(已在 listening-king 用 ^5.4.0,05 net 层基础)做流式 HTTP,镜像上游 `forwardStreamRequest`:

```dart
class StreamCallbacks {
  final void Function(LLMStreamChunk chunk) onChunk;
  final void Function(LLMUsage usage) onEnd;
  final void Function(String error) onError;
  const StreamCallbacks({required this.onChunk, required this.onEnd, required this.onError});
}

Future<void> forwardStreamRequest({
  required ProviderDb provider,        // 含 endpoint/key/adapter_type(06 drift)
  required LLMRequest request,
  required StreamCallbacks callbacks,
  required CancelToken cancelToken,    // 取消锚点(见 §5)
}) async {
  final mapping = getModelMapping(provider, request.model); // relayModel→providerModel
  final adapter = ProviderAdapter.forType(provider.adapterType)..; // 逐调用新实例
  final built = adapter.buildRequest(/* ...stream: true */);

  // 1) Content-Type 校验(检测假流式):响应头必须含 text/event-stream(Gemini 例外,
  //    application/json 流)——超集校验,与上游一致。
  // 2) 30s 空闲超时(STREAM_IDLE_TIMEOUT_MS):每个 chunk 重置 Timer,超时 onError("idle timeout")。
  // 3) 逐行读取 dio ResponseBody.stream(ResponseType.stream),交 adapter.parseStreamLine:
  //    ChunkEvent→onChunk;UsageEvent→暂存;DoneEvent→收尾。
  // 4) 收尾:无 usage → 兜底 {0,0,0}(与上游一致,记警告);chunkCount==0 → 警告(可能解析漏)。
  //    调 onEnd(usage)。
}
```

- **idle 超时**:用 `Timer`(每个 chunk 重置)而非 `dio.receiveTimeout`(后者是首字节/总时长,不匹配「无新数据」语义)。上游用 `withTimeout` race,移植成 Timer 等价。
- **SSE 逐行**:dio `ResponseBody.stream` 产 `List<int>`,按 `\n` 切行(跨 chunk 边界累积 buffer)。Gemini 走 JSON 流分支(逐对象,非 `data:` 前缀)。**解析器在 adapter 内**,forwarder 只喂原始行——与上游职责一致。

### 5. 取消语义(`StreamDispatcher` + WS 层契约)

镜像上游 WS client 的 `streamControllers: Map<requestId, AbortController>` + `abortAllStreams`:

```dart
/// core/forwarder/stream_dispatcher.dart —— 桥接 RelayClient ↔ Forwarder,管取消。
class StreamDispatcher {
  final Forwarder _forwarder;
  final RelayClient _relay;          // 03:发 llm_stream_chunk/end/error/cancel
  final ProviderLogDao _log;          // 06:insert/complete/fail
  final Map<String /*requestId*/, CancelToken> _active = {};

  Future<void> handleLlmRequest(LLMRequest req) async {
    final token = CancelToken();
    _active[req.id] = token;
    _log.insertRecord(req, getQuotationAtTime(req.model)); // 时点价快照,pending
    final sw = Stopwatch()..start();
    try {
      await _forwarder.forwardStreamRequest(
        provider: resolveProvider(req.model),
        request: req,
        cancelToken: token,
        callbacks: StreamCallbacks(
          onChunk: (c) => _relay.send(RelayMessage.llmStreamChunk(c)),
          onEnd:   (u) {
            final amount = computeAmount(inPrice, outPrice, u); // round((in*prompt+out*completion)/1000) nUSD
            _log.completeRecord(req.id, u, amount, sw.elapsedMilliseconds);
            _relay.send(RelayMessage.llmStreamEnd(usage: u, providerSignature: '')); // 恒空串(01)
          },
          onError: (e) {
            _log.failRecord(req.id, e);
            _relay.send(RelayMessage.llmError(req.id, e));
          },
        ),
      );
    } finally {
      _active.remove(req.id);
    }
  }

  void handleStreamCancel(String requestId) {
    final t = _active[requestId];
    if (t != null) { t.cancel(); /* 触发 forwardStreamRequest 抛 CancelException→onError 路径 */ }
  }

  /// WS 断开时 RelayClient 调:中止所有在飞流(上游 abortAllStreams)。
  void abortAll() {
    for (final t in _active.values) t.cancel();
    _active.clear();
  }
}
```

- **取消传播链**:`llm_stream_cancel`(中转站)→ `RelayClient` → `dispatcher.handleStreamCancel` → `CancelToken.cancel()` → dio 中止 HTTP → `forwardStreamRequest` 抛 `DioException(type: cancel)` → 走 onError → `failRecord` + `llm_error`。与上游 `AbortController`→fetch abort→onError 完全同构。
- **WS 断开**:03 的 `RelayClient` 在连接丢失/重连前调 `dispatcher.abortAll()`(镜像上游),防止孤立流挂在已死的 WS 上、onEnd/onError 无处回吐。

### 6. 与 03 WS 层的接口契约

`RelayClient`(03)↔ `StreamDispatcher` 的接缝,四条消息:

| 方向 | 消息 | 契约 |
|---|---|---|
| WS→dispatcher | `llm_request` | `RelayClient` 解 envelope 后调 `dispatcher.handleLlmRequest(req)`。dispatcher **同步返回**(不阻塞 WS 读循环),转发在后台 Future 跑。 |
| dispatcher→WS | `llm_stream_chunk` | 每条 `onChunk` → `relay.send`。**保持顺序**:单请求内 chunk 必须按上游到达序发(同 Future 链串行,勿并发)。 |
| dispatcher→WS | `llm_stream_end` | `onEnd` 一次,带 `usage` + `providerSignature: ""`(恒空串,01)。**之后不再发该 requestId 的消息**。 |
| dispatcher→WS | `llm_error` | `onError` 一次,替代 end(失败无 end)。 |
| WS→dispatcher | `llm_stream_cancel` | `RelayClient` 调 `dispatcher.handleStreamCancel(requestId)`。dispatcher 保证:取消后该 requestId 不再有 chunk/end/error 外泄(dio 中止后丢弃残余)。 |

- **`providerSignature` 恒 `""`**:forwarder **无需 crypto**(01 结论解除 09 对 01 的依赖);结算锚定 Polygon `Settled` 事件(02),与链下签名解耦。dispatcher 构 `llm_stream_end` 直接填空串。
- **requestId 归属**:由中转站分配(协议),dispatcher 用它索引 `_active` Map。cancel/end/error 三者幂等:重复 end/cancel 不二次记 log(cancel 已 abort 的流是 no-op)。

### 7. amount 与时点价(06 联动)

- `insertRecord` 时 `getQuotationAtTime(model, ts)` 拍**时点价快照**(防止结算时报价已变,与上游 relay-records 一致)。
- `onEnd` 算 `amount = round((inPrice×prompt_tokens + outPrice×completion_tokens)/1000)` nUSD(上游公式),`completeRecord` 落库。失败 `failRecord`(status=failed + error_message)。

### 8. 风险与待验证(留 11)

- **`web_socket_channel` 无 TCP keepalive**(03 坑):forwarder 不直接管 WS,但 WS 静默断时 forwarder 的在飞流需 `abortAll` 兜底——依赖 03 的断连检测及时。11 联调验证断连→abort 时序。
- **Gemini JSON 流 vs SSE**:`ResponseType.stream` 对两者都返回字节流,但解析分支不同;adapter 内判 `type` 选解析器。11 联调覆盖 Gemini 一条真实往返。
- **大 `llm_request` body**(MB 级,05 坑):`buildRequest` 的 JSON 序列化在主 isolate;若 profile 出 jank,挪 `compute()`(05 约定)。暂不预优化(Rule 2)。
- **dio 流式 + CancelToken**:需验证 `CancelToken.cancel()` 在流式读取中途确实中止底层 socket(不残留连接)。11 联调时强制取消一条在飞流验证。

### 下游影响

- **解锁 11**(端到端 LLM 往返):09 是 11 的最后阻塞,现 05+09 均解 → **11 进边界**。11 用本 ticket 的 adapter 抽象 + 流式管线做一次真实上游往返(需人提供 LLM API key)。
- **下游实现 ticket**:forwarder 实现(适配器 5 份 + dispatcher + forwarder.dart + provider_log 插桩)待真实 app 脚手架(05 骨架)落地后启动;本 ticket 给定接口契约与上游映射,实现时按 §2–§7 逐条对照。
