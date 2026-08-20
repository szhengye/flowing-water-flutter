import 'dart:convert';

import '../../relay/messages.dart';
import 'types.dart';

/// Anthropic Messages 适配器 —— 逐行移植 `web3-api/.../adapters/anthropic.ts`。
///
/// 与 OpenAI 系的关键差异:
/// - **per-stream 状态**([_openToolUses]):tool_use 块按 index 记 id/name,流式
///   input_json_delta 拼回 arguments。**非 const**;factory `makeAdapter` 每次新建
///   实例,隔离并发流(姊妹 09 §2)。
/// - **buildRequest 重构 body**:system 抽到顶层、`max_tokens` 默认 4096、`stop`
///   →`stop_sequences`、header `x-api-key`+`anthropic-version`。
/// - **parseStreamLine 按 `obj.type` 事件分发**:text_delta→content、
///   input_json_delta→tool_calls.arguments、thinking_delta→reasoning_content。
class AnthropicAdapter implements ProviderAdapter {
  AnthropicAdapter();

  static const _anthropicVersion = '2023-06-01';
  static const _defaultMaxTokens = 4096;

  /// index → (id, name):当前打开的 tool_use 块。content_block_stop 清除。
  final Map<int, ({String id, String name})> _openToolUses = {};

  @override
  AdapterType get type => AdapterType.anthropic;

  static String resolveEndpoint(String endpoint) {
    final trimmed = endpoint.replaceAll(RegExp(r'/+$'), '');
    if (trimmed.endsWith('/v1')) return '$trimmed/messages';
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
    // system 抽到顶层(Anthropic messages 不含 role:system);content join \n\n。
    final sysText = request.messages
        .where((m) => m['role'] == 'system')
        .map((m) => (m['content'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .join('\n\n');
    final conv = request.messages
        .where((m) => m['role'] != 'system')
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final e = request.extra;

    final body = <String, dynamic>{
      'model': providerModel,
      'messages': conv,
      'max_tokens': e['max_tokens'] ?? _defaultMaxTokens,
      'stream': stream,
    };
    if (sysText.isNotEmpty) body['system'] = sysText;
    if (e.containsKey('temperature')) body['temperature'] = e['temperature'];
    if (e.containsKey('top_p')) body['top_p'] = e['top_p'];
    if (e.containsKey('top_k')) body['top_k'] = e['top_k'];
    if (e.containsKey('stop')) {
      final stop = e['stop'];
      body['stop_sequences'] = stop is List ? stop : [stop];
    }
    if (e.containsKey('tools')) body['tools'] = e['tools'];
    if (e.containsKey('tool_choice')) body['tool_choice'] = e['tool_choice'];
    for (final k in const ['metadata', 'thinking', 'service_tier']) {
      if (e.containsKey(k)) body[k] = e[k];
    }

    return AdapterRequest(
      resolveEndpoint(providerEndpoint),
      {
        'Content-Type': 'application/json',
        'x-api-key': providerApiKey,
        'anthropic-version': _anthropicVersion,
      },
      jsonEncode(body),
    );
  }

  @override
  StreamEvent? parseStreamLine(String line, String providerModel) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('data: ')) return null;
    final data = trimmed.substring(6);
    if (data.isEmpty) return null;
    Map<String, dynamic> obj;
    try {
      obj = jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
    final type = obj['type'] as String?;
    final index = obj['index'] as int?;
    switch (type) {
      case 'message_start':
        return StreamEvent(chunk: _chunk(obj, providerModel, delta: {'role': 'assistant'}));
      case 'content_block_start':
        final cb = obj['content_block'] as Map<String, dynamic>?;
        if (cb != null && cb['type'] == 'tool_use' && index != null) {
          _openToolUses[index] = (
            id: (cb['id'] as String?) ?? '',
            name: (cb['name'] as String?) ?? '',
          );
          return StreamEvent(
            chunk: _chunk(obj, providerModel, delta: {
              'tool_calls': [
                {
                  'index': index,
                  'id': cb['id'],
                  'type': 'function',
                  'function': {'name': cb['name'], 'arguments': ''},
                }
              ],
            }),
          );
        }
        return null; // text/thinking/image:content 由 delta 到达
      case 'content_block_delta':
        final delta = obj['delta'] as Map<String, dynamic>?;
        final dt = delta?['type'] as String?;
        if (dt == 'text_delta') {
          return StreamEvent(chunk: _chunk(obj, providerModel, delta: {
            'content': delta!['text'] ?? '',
          }));
        }
        if (dt == 'input_json_delta' && index != null) {
          // 仅当该 index 有打开的 tool_use 块才发,否则 stray 丢弃(上游同)。
          if (!_openToolUses.containsKey(index)) return null;
          return StreamEvent(chunk: _chunk(obj, providerModel, delta: {
            'tool_calls': [
              {
                'index': index,
                'function': {'arguments': delta!['partial_json'] ?? ''},
              }
            ],
          }));
        }
        if (dt == 'thinking_delta') {
          return StreamEvent(chunk: _chunk(obj, providerModel, delta: {
            'reasoning_content': delta!['thinking'] ?? '',
          }));
        }
        return null; // signature_delta/citations_delta 等:drop
      case 'content_block_stop':
        if (index != null) _openToolUses.remove(index);
        return null; // OpenAI 流在 tool_call 关闭时不发任何东西
      case 'message_delta':
        LlmUsage? usage;
        final u = obj['usage'];
        if (u is Map) {
          final m = Map<String, dynamic>.from(u);
          final out = (m['output_tokens'] as num?)?.toInt() ?? 0;
          usage = LlmUsage(
            promptTokens: 0, // input_tokens 在 message_start,流式此处无
            completionTokens: out,
            totalTokens: out,
            extra: m, // 保留 output_tokens/cache_*/input_tokens 等原字段
          );
        }
        String? finish;
        final sr = (obj['delta'] as Map?)?['stop_reason'];
        if (sr != null) finish = mapStopReason(sr);
        return StreamEvent(
          chunk: _chunk(obj, providerModel, delta: {}, finishReason: finish),
          usage: usage,
        );
      case 'message_stop':
        return const StreamEvent(done: true);
      default:
        return null;
    }
  }

  /// 基础 chunk 骨架(id/model 取自 obj.message,缺省兜底)。
  LlmStreamChunk _chunk(
    Map<String, dynamic> obj,
    String providerModel, {
    required Map<String, dynamic> delta,
    String? finishReason,
  }) {
    final msg = obj['message'] as Map<String, dynamic>?;
    final now = DateTime.now().millisecondsSinceEpoch;
    return LlmStreamChunk(
      id: (msg?['id'] as String?) ?? 'msg-$now',
      object: 'chat.completion.chunk',
      created: now ~/ 1000,
      model: (msg?['model'] as String?) ?? providerModel,
      choices: [
        {
          'index': 0,
          'delta': delta,
          'finish_reason': finishReason,
        }
      ],
    );
  }

  /// Anthropic stop_reason → OpenAI finish_reason(上游 mapAnthropicStopReason)。
  static String? mapStopReason(Object? reason) {
    if (reason == 'max_tokens') return 'length';
    if (reason == 'end_turn' || reason == 'stop_sequence') return 'stop';
    if (reason == 'tool_use') return 'tool_calls';
    if (reason == 'refusal') return 'content_filter';
    return null;
  }
}
