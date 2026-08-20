import 'dart:convert';

/// relay WS 协议消息层 —— wayfinder ticket 01 / Slice A。
///
/// 协议权威:`web3-api/packages/shared/src/protocol/messages.ts`。绝大多数消息是
/// envelope `{type, payload}`,唯有 3 个 `query_settlement*` 把字段放在**顶层**
/// (按 `tx` 关联,无 payload/requestId)。encode/decode 必须先按 `type` 拦截这三型
/// ——否则它们没有 payload 包裹,会被当成畸形消息(姊妹 spike 03 踩过的坑)。
///
/// 本层只负责 framing + type 派发:握手消息(Auth / AuthAck / ProviderInfo /
/// Heartbeat)、`query_settlement` 三型,以及 LLM 流式五型(`llm_request` /
/// `llm_stream_cancel` 入站;`llm_stream_chunk` / `llm_stream_end` / `llm_error`
/// 出站)在此完整定型(02 提升);其余 type(03 的 query_response 等)仍归
/// [UnknownRelayMessage](不崩溃,保留原始 payload 供后续精确派发)。

// ─────────────────────────────────────────────────────────────────────────
//  消息类型
// ─────────────────────────────────────────────────────────────────────────

sealed class RelayMessage {
  const RelayMessage();
}

// ── 握手消息(envelope) ──────────────────────────────────────────────────

/// provider → relay:对 challenge 的 EIP-191 签名应答。
class Auth extends RelayMessage {
  const Auth({
    required this.address,
    required this.paymentAddress,
    required this.signature,
  });
  final String address;
  final String paymentAddress;
  final String signature;
}

/// relay → provider:握手结果。success+challenge(下一次握手用)/ 失败+error。
class AuthAck extends RelayMessage {
  const AuthAck({required this.success, this.challenge, this.error});
  final bool success;
  final String? challenge;
  final String? error;
}

/// provider_info 上报的单一模型条目。中转站只读 [relayModel](TS 多发的 name 被忽略)。
class ProviderModel {
  const ProviderModel({
    required this.relayModel,
    required this.inputPricePer1k,
    required this.outputPricePer1k,
  });
  final String relayModel;
  final int inputPricePer1k; // nUSD / 1K tokens
  final int outputPricePer1k; // nUSD / 1K tokens
}

/// provider → relay:鉴权后上报的模型清单 + 报价(成功后 500ms 发,relay 不回 ack)。
class ProviderInfo extends RelayMessage {
  const ProviderInfo({
    required this.address,
    required this.paymentAddress,
    required this.models,
    this.supportsStream = true,
  });
  final String address;
  final String paymentAddress;
  final List<ProviderModel> models;
  final bool supportsStream;
}

/// 应用层心跳(双向;relay 原样回包,relay 端 60s 无心跳即断开 + abort 所有流)。
class Heartbeat extends RelayMessage {
  const Heartbeat(this.timestamp);
  final int timestamp; // epoch ms
}

// ── query_settlement 三型(非 envelope,字段在顶层,按 tx 关联) ──────────

/// provider → relay:查某 tx 的链上结算记录。
class QuerySettlement extends RelayMessage {
  const QuerySettlement(this.tx);
  final String tx;
}

/// 链上结算明细记录(wire 用 snake_case)。
class SettlementRecord {
  const SettlementRecord({
    required this.requestId,
    required this.inputTokens,
    required this.outputTokens,
    required this.amount,
    required this.processingStatus,
  });
  final String requestId;
  final int inputTokens;
  final int outputTokens;
  final int amount; // nUSD
  final String processingStatus;
}

/// relay → provider:settlement 查询成功结果。
class QuerySettlementResult extends RelayMessage {
  const QuerySettlementResult({required this.tx, required this.records});
  final String tx;
  final List<SettlementRecord> records;
}

/// relay → provider:settlement 查询失败(not_found / unauthorized / internal)。
class QuerySettlementError extends RelayMessage {
  const QuerySettlementError({required this.tx, required this.reason});
  final String tx;
  final String reason;
}

// ── relay_log 反查(06 链上对账;envelope,按 requestId 请求/响应关联) ──────

/// provider → relay:按 (tx, logIndex) 反查归属本笔 settle 的 relay_log 记录。
/// 与 [QuerySettlement](tx 单键、无 requestId)是**不同**的查询;响应统一走
/// [QueryResponse],按 requestId 关联(q_{ts}_{rand8})。wire 字段名 `logindex` 小写。
class QueryRelayRecordsByTxLogindex extends RelayMessage {
  const QueryRelayRecordsByTxLogindex({
    required this.requestId,
    required this.tx,
    required this.logindex,
  });
  final String requestId;
  final String tx;
  final int logindex;
}

/// provider → relay:查 relay 的模型目录(`relay_models`),同步到本地 `provider_models`。
/// 响应统一走 [QueryResponse](按 requestId 关联),`data` = relay_models 行数组
/// (model_name / display_name / context_window / max_output_tokens / modality /
/// prompt_price / completion_price)。[q] 可选,模糊匹配;空 = 全量目录。
class QueryModelParams extends RelayMessage {
  const QueryModelParams({required this.requestId, this.q});
  final String requestId;
  final String? q;
}

/// relay → provider:任意 query 的统一响应(按 requestId 关联)。`ok=true` 时 [data]
/// 为记录数组(06:RelayRecord[],每条含 request_id 等 snake_case 字段);`ok=false`
/// 时 [error] 为原因。data 可能是数组,也可能是 `{records: [...]}` 包裹 —— decode 统一拆平。
class QueryResponse extends RelayMessage {
  const QueryResponse({
    required this.requestId,
    required this.ok,
    this.data = const [],
    this.error,
  });
  final String requestId;
  final bool ok;
  final List<Map<String, dynamic>> data;
  final String? error;
}

// ── LLM 流式数据类(02) ───────────────────────────────────────────────────
//  协议权威:web3-api/packages/shared/src/types/llm.ts。这些是「数据载体」(透传
//  负载),非协议信令;承载 TS 的 `[k: string]: unknown` catch-all 时用「强类型核心
//  字段 + [extra] map」:已知字段进 typed,其余原样收进 extra,toJson 合并输出——
//  既忠实透传厂商字段(reasoning / role:null / cache_* / stream_options ...),又
//  不丢失结构。OpenAI adapter 不拆解 messages/choices,故用 List<Map> 透传;
//  Anthropic/Gemini 拆解留后续会话(YAGNI)。

/// 统一 LLM 请求体(对应 TS LLMRequest,OpenAI Chat Completions 形状)。
/// 经 `llm_request.payload.request` 入站;forwarder 把它整包透传给 adapter。
class LlmRequest {
  const LlmRequest({
    required this.model,
    required this.messages,
    this.stream,
    this.extra = const {},
  });

  final String model;
  final List<Map<String, dynamic>> messages;
  final bool? stream;
  final Map<String, dynamic> extra; // temperature/max_tokens/tools/tool_choice/...

  /// 合并成上游 body(已知字段 + extra,extra 先铺底、typed 覆盖)。
  Map<String, dynamic> toJson() {
    final out = Map<String, dynamic>.from(extra);
    out['model'] = model;
    out['messages'] = messages;
    if (stream != null) out['stream'] = stream;
    return out;
  }

  static LlmRequest fromJson(Map<String, dynamic> j) {
    final extra = Map<String, dynamic>.from(j);
    final model = extra.remove('model') as String;
    final messages = (extra.remove('messages') as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        const <Map<String, dynamic>>[];
    final stream = extra.remove('stream');
    return LlmRequest(
      model: model,
      messages: messages,
      stream: stream is bool ? stream : null,
      extra: extra,
    );
  }
}

/// 流式增量块(对应 TS LLMStreamChunk)。choices 透传(delta/finish_reason/logprobs)。
class LlmStreamChunk {
  const LlmStreamChunk({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    this.extra = const {},
  });

  final String id;
  final String object; // 'chat.completion.chunk'
  final int created;
  final String model;
  final List<Map<String, dynamic>> choices;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() {
    final out = Map<String, dynamic>.from(extra);
    out['id'] = id;
    out['object'] = object;
    out['created'] = created;
    out['model'] = model;
    out['choices'] = choices;
    return out;
  }
}

/// token 用量(对应 TS LLMUsage)。wire 用 snake_case(prompt_tokens),extra 承载
/// prompt_tokens_details / cache_* / server_tool_use 等厂商子字段。
class LlmUsage {
  const LlmUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    this.extra = const {},
  });

  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() {
    final out = Map<String, dynamic>.from(extra);
    out['prompt_tokens'] = promptTokens;
    out['completion_tokens'] = completionTokens;
    out['total_tokens'] = totalTokens;
    return out;
  }
}

// ── LLM 流式信令(envelope) ───────────────────────────────────────────────

/// relay → provider:一次 LLM 请求(含 relay 签名,本 app 不验 —— 结算锚链上,01)。
class LlmRequestMessage extends RelayMessage {
  const LlmRequestMessage({
    required this.requestId,
    required this.request,
    this.relaySignature = '',
  });
  final String requestId;
  final LlmRequest request;
  final String relaySignature;
}

/// relay → provider:中转站取消在飞流(reason: client_disconnected/timeout/admin_kill)。
class LlmStreamCancelMessage extends RelayMessage {
  const LlmStreamCancelMessage({required this.requestId, this.reason});
  final String requestId;
  final String? reason;
}

/// provider → relay:一条流式增量。
class LlmStreamChunkMessage extends RelayMessage {
  const LlmStreamChunkMessage({required this.requestId, required this.chunk});
  final String requestId;
  final LlmStreamChunk chunk;
}

/// provider → relay:流正常结束(带 usage;providerSignature 本 app 恒空串,01)。
class LlmStreamEndMessage extends RelayMessage {
  const LlmStreamEndMessage({
    required this.requestId,
    required this.usage,
    this.providerSignature = '',
  });
  final String requestId;
  final LlmUsage usage;
  final String providerSignature;
}

/// provider → relay:流异常(取代 end;失败无 end)。code 如 upstream_500 / upstream_non_sse。
class LlmErrorMessage extends RelayMessage {
  const LlmErrorMessage({
    required this.requestId,
    required this.code,
    required this.message,
  });
  final String requestId;
  final String code;
  final String message;
}

// ── decode 兜底 ──────────────────────────────────────────────────────────

/// 未在此层定型的消息(LLM 流式、其余 query 等)。保留 type + 原始 payload,
/// 02/03 提升为具名子类后即可精确派发;在此之前调用方可安全忽略。
class UnknownRelayMessage extends RelayMessage {
  const UnknownRelayMessage(this.type, [this.payload]);
  final String type;
  final Map<String, dynamic>? payload;
}

// ─────────────────────────────────────────────────────────────────────────
//  codec
// ─────────────────────────────────────────────────────────────────────────

/// 把一条出站(provider → relay)消息编码为 relay WS 线协议字符串。
///
/// 入站消息([AuthAck] / [QuerySettlementResult] / [QuerySettlementError] /
/// [UnknownRelayMessage])不可编码 —— provider 永不发送它们,调用即抛
/// [UnsupportedError]。
String encodeMessage(RelayMessage msg) {
  Map<String, dynamic> wire;
  switch (msg) {
    case Auth(:final address, :final paymentAddress, :final signature):
      wire = {
        'type': 'auth',
        'payload': {
          'address': address,
          'paymentAddress': paymentAddress,
          'signature': signature,
        },
      };
    case AuthAck():
    case QuerySettlementResult():
    case QuerySettlementError():
    case QueryResponse():
    case LlmRequestMessage():
    case LlmStreamCancelMessage():
    case UnknownRelayMessage():
      // 入站消息(relay → provider)或 decode 兜底产物 —— provider 永不发送。
      throw UnsupportedError('provider 不发送入站消息: ${msg.runtimeType}');
    case ProviderInfo(
      :final address,
      :final paymentAddress,
      :final models,
      :final supportsStream
    ):
      wire = {
        'type': 'provider_info',
        'payload': {
          'address': address,
          'paymentAddress': paymentAddress,
          'models': [
            for (final m in models)
              {
                'relayModel': m.relayModel,
                'inputPricePer1k': m.inputPricePer1k,
                'outputPricePer1k': m.outputPricePer1k,
              },
          ],
          'supportsStream': supportsStream,
        },
      };
    case Heartbeat(:final timestamp):
      wire = {
        'type': 'heartbeat',
        'payload': {'timestamp': timestamp},
      };
    case QuerySettlement(:final tx):
      // 非 envelope:tx 在顶层,无 payload 包裹。
      wire = {'type': 'query_settlement', 'tx': tx};
    case QueryRelayRecordsByTxLogindex(
      :final requestId,
      :final tx,
      :final logindex
    ):
      wire = {
        'type': 'query_relay_records_by_tx_logindex',
        'payload': {'requestId': requestId, 'tx': tx, 'logindex': logindex},
      };
    case QueryModelParams(:final requestId, :final q):
      final payload = <String, dynamic>{'requestId': requestId};
      if (q != null) payload['q'] = q;
      wire = {'type': 'query_model_params', 'payload': payload};
    case LlmStreamChunkMessage(
      :final requestId,
      :final chunk
    ):
      wire = {
        'type': 'llm_stream_chunk',
        'payload': {'requestId': requestId, 'chunk': chunk.toJson()},
      };
    case LlmStreamEndMessage(
      :final requestId,
      :final usage,
      :final providerSignature
    ):
      wire = {
        'type': 'llm_stream_end',
        'payload': {
          'requestId': requestId,
          'usage': usage.toJson(),
          'providerSignature': providerSignature,
        },
      };
    case LlmErrorMessage(:final requestId, :final code, :final message):
      wire = {
        'type': 'llm_error',
        'payload': {'requestId': requestId, 'code': code, 'message': message},
      };
  }
  return jsonEncode(wire);
}

/// 把一条入站 WS 线协议字符串解码为 [RelayMessage]。
///
/// - 畸形 JSON / 顶层非对象 → 抛 [FormatException](由调用方决定记日志或断连)。
/// - 已知 type → 对应具名子类。
/// - 未知 type(含 02/03 待提升的 LLM / query 型)→ [UnknownRelayMessage]。
RelayMessage decodeMessage(String raw) {
  final Object? decoded = jsonDecode(raw); // 畸形 JSON 抛 FormatException
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('relay 消息顶层非 JSON 对象: $raw');
  }
  final json = decoded;
  final type = json['type'] as String?;

  // 非 envelope 三型:先拦截(字段在顶层,无 payload 包裹)。
  if (type == 'query_settlement') {
    return QuerySettlement(json['tx'] as String);
  }
  if (type == 'query_settlement_result') {
    return QuerySettlementResult(
      tx: json['tx'] as String,
      records: [
        for (final r in (json['records'] as List?) ?? const [])
          _decodeSettlementRecord(r as Map<String, dynamic>),
      ],
    );
  }
  if (type == 'query_settlement_error') {
    return QuerySettlementError(
      tx: json['tx'] as String,
      reason: json['reason'] as String,
    );
  }

  // 标准 envelope {type, payload}。
  final payload =
      (json['payload'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
  return switch (type) {
    'auth' => Auth(
        address: payload['address'] as String,
        paymentAddress: payload['paymentAddress'] as String,
        signature: payload['signature'] as String,
      ),
    'auth_ack' => AuthAck(
        success: (payload['success'] as bool?) ?? false,
        challenge: payload['challenge'] as String?,
        error: payload['error'] as String?,
      ),
    'provider_info' => ProviderInfo(
        address: payload['address'] as String,
        paymentAddress: payload['paymentAddress'] as String,
        models: [
          for (final m in (payload['models'] as List?) ?? const [])
            _decodeProviderModel(m as Map<String, dynamic>),
        ],
        supportsStream: (payload['supportsStream'] as bool?) ?? true,
      ),
    'heartbeat' => Heartbeat(payload['timestamp'] as int),
    'llm_request' => LlmRequestMessage(
        requestId: payload['requestId'] as String,
        request: LlmRequest.fromJson(
          Map<String, dynamic>.from(payload['request'] as Map),
        ),
        relaySignature: (payload['relaySignature'] as String?) ?? '',
      ),
    'llm_stream_cancel' => LlmStreamCancelMessage(
        requestId: payload['requestId'] as String,
        reason: payload['reason'] as String?,
      ),
    'query_response' => QueryResponse(
        requestId: payload['requestId'] as String,
        ok: (payload['ok'] as bool?) ?? false,
        data: _decodeQueryResponseData(payload['data']),
        error: payload['error'] as String?,
      ),
    _ => UnknownRelayMessage(type ?? '', payload),
  };
}

SettlementRecord _decodeSettlementRecord(Map<String, dynamic> r) =>
    SettlementRecord(
      requestId: r['request_id'] as String,
      inputTokens: r['input_tokens'] as int,
      outputTokens: r['output_tokens'] as int,
      amount: r['amount'] as int,
      processingStatus: r['processing_status'] as String,
    );

/// query_response.data 可能直接是 RelayRecord[],也可能是 `{records: [...]}` 包裹;
/// 统一拆成 List<Map>(非 Map 元素丢弃,防畸形)。
List<Map<String, dynamic>> _decodeQueryResponseData(Object? raw) {
  final List list;
  if (raw is List) {
    list = raw;
  } else if (raw is Map && raw['records'] is List) {
    list = raw['records'] as List;
  } else {
    return const [];
  }
  return [
    for (final r in list)
      if (r is Map) Map<String, dynamic>.from(r),
  ];
}

ProviderModel _decodeProviderModel(Map<String, dynamic> m) => ProviderModel(
      relayModel: m['relayModel'] as String,
      inputPricePer1k: m['inputPricePer1k'] as int,
      outputPricePer1k: m['outputPricePer1k'] as int,
    );
