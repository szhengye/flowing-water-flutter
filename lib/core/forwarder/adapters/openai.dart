import 'dart:convert';

import '../../relay/messages.dart';
import 'types.dart';

/// OpenAI Chat Completions 适配器 —— 逐行移植 `web3-api/.../adapters/openai.ts`。
///
/// 协议:`/v1/chat/completions` SSE,data 行 `choices[].delta` + 末尾 usage(需
/// `stream_options.include_usage=true`,否则兼容网关可能不发 usage → relay 漏计)。
/// DeepSeek 与 Azure 后续委托本类(同协议,仅 endpoint/header 差异)。
class OpenAIAdapter implements ProviderAdapter {
  const OpenAIAdapter();

  @override
  AdapterType get type => AdapterType.openai;

  /// endpoint 若是 base URL(以 /v1 结尾)则自动补全 /chat/completions(上游同逻辑)。
  static String resolveEndpoint(String endpoint) {
    final trimmed = endpoint.replaceAll(RegExp(r'/+$'), '');
    if (trimmed.endsWith('/v1')) return '$trimmed/chat/completions';
    return endpoint;
  }

  @override
  AdapterRequest buildRequest({
    required String providerEndpoint,
    required String providerApiKey,
    required String providerModel,
    required LlmRequest request,
    required bool stream,
  }) {
    // request.toJson() 已含原 relay model;providerModel 覆盖之。upstream wins。
    final body = <String, dynamic>{
      ...request.toJson(),
      'model': providerModel,
      'stream': stream,
    };
    // 流式强制注入 include_usage(防漏计);调用方已显式设则尊重(含 include_usage:false)。
    if (stream) {
      final so = body['stream_options'];
      final includeUsage = so is Map ? so['include_usage'] : null;
      if (includeUsage == null) {
        body['stream_options'] = <String, dynamic>{
          if (so is Map) ...Map<String, dynamic>.from(so),
          'include_usage': true,
        };
      }
    }
    return AdapterRequest(
      resolveEndpoint(providerEndpoint),
      {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $providerApiKey',
      },
      jsonEncode(body),
    );
  }

  @override
  StreamEvent? parseStreamLine(String line, String providerModel) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('data: ')) return null;
    final data = trimmed.substring(6); // 去 "data: " 前缀
    if (data == '[DONE]') return const StreamEvent(done: true);
    try {
      final obj = jsonDecode(data) as Map<String, dynamic>;
      return StreamEvent(chunk: _parseChunk(obj, providerModel), usage: _parseUsage(obj));
    } catch (_) {
      return null; // 畸形 data 行:忽略,不让坏行打掉整条流(上游同 catch→null)
    }
  }

  /// 透传 delta(tool_calls/function_call/audio/refusal/role/name/...),upstream wins。
  LlmStreamChunk _parseChunk(Map<String, dynamic> obj, String providerModel) {
    final extra = <String, dynamic>{};
    for (final k in obj.keys) {
      if (const {'id', 'object', 'created', 'model', 'choices', 'usage'}.contains(k)) {
        continue;
      }
      extra[k] = obj[k];
    }
    return LlmStreamChunk(
      id: (obj['id'] as String?) ?? 'cmpl-${DateTime.now().millisecondsSinceEpoch}',
      object: (obj['object'] as String?) ?? 'chat.completion.chunk',
      created: (obj['created'] as int?) ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      model: (obj['model'] as String?) ?? providerModel,
      choices: [
        for (final raw in (obj['choices'] as List?) ?? const <dynamic>[])
          _parseChoice(raw as Map<String, dynamic>),
      ],
      extra: extra,
    );
  }

  Map<String, dynamic> _parseChoice(Map<String, dynamic> c) {
    final deltaRaw = c['delta'];
    final delta = <String, dynamic>{};
    if (deltaRaw is Map) delta.addAll(Map<String, dynamic>.from(deltaRaw));
    delta.putIfAbsent('content', () => ''); // 缺省 ""(上游 c.delta?.content ?? "")
    // role 不强加(上游 c.delta?.role 可能 undefined;JSON 不输出)。
    return <String, dynamic>{
      'index': c['index'] ?? 0,
      'delta': delta,
      'finish_reason': c['finish_reason'], // null 透传
      if (c.containsKey('logprobs')) 'logprobs': c['logprobs'],
    };
  }

  LlmUsage? _parseUsage(Map<String, dynamic> obj) {
    final u = obj['usage'];
    if (u is! Map) return null;
    final m = Map<String, dynamic>.from(u);
    final extra = Map<String, dynamic>.from(m)
      ..remove('prompt_tokens')
      ..remove('completion_tokens')
      ..remove('total_tokens');
    return LlmUsage(
      promptTokens: (m['prompt_tokens'] as num?)?.toInt() ?? 0,
      completionTokens: (m['completion_tokens'] as num?)?.toInt() ?? 0,
      totalTokens: (m['total_tokens'] as num?)?.toInt() ?? 0,
      extra: extra, // prompt_tokens_details / cache_* 等子字段透传
    );
  }
}
