import 'dart:convert';

import '../../relay/messages.dart';
import 'types.dart';

/// Google Gemini 适配器 —— 逐行移植 `web3-api/.../adapters/gemini.ts`。
///
/// 与 OpenAI 系的关键差异:
/// - **buildRequest 重构**:URL `{base}/v1beta/models/{model}:streamGenerateContent?key=`;
///   OpenAI messages → Gemini contents(system→systemInstruction、assistant→model、
///   tool→functionResponse、assistant+tool_calls→functionCall);header 仅 Content-Type
///   (key 在 URL,不在 header)。
/// - **parseStreamLine 处理原始 JSON 流**(非 SSE):每行一个 JSON 对象(部分代理包
///   `data: ` 前缀,故兼容剥离);usageMetadata → usage。无 per-stream 状态 → const。
class GeminiAdapter implements ProviderAdapter {
  const GeminiAdapter();

  @override
  AdapterType get type => AdapterType.gemini;

  @override
  AdapterRequest buildRequest({
    required String providerEndpoint,
    required String providerApiKey,
    required String providerModel,
    required LlmRequest request,
    required bool stream,
  }) {
    final base = providerEndpoint.replaceAll(RegExp(r'/+$'), '');
    final action = stream ? 'streamGenerateContent' : 'generateContent';
    final url =
        '$base/v1beta/models/${Uri.encodeComponent(providerModel)}:$action?key=${Uri.encodeComponent(providerApiKey)}';

    final sysText = request.messages
        .where((m) => m['role'] == 'system')
        .map((m) => (m['content'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .join('\n\n');
    final contents = request.messages
        .where((m) => m['role'] != 'system')
        .map(_convertMessage)
        .toList();

    final e = request.extra;
    final generationConfig = <String, dynamic>{};
    if (e.containsKey('temperature')) generationConfig['temperature'] = e['temperature'];
    if (e.containsKey('top_p')) generationConfig['topP'] = e['top_p'];
    if (e.containsKey('top_k')) generationConfig['topK'] = e['top_k'];
    if (e.containsKey('max_tokens')) generationConfig['maxOutputTokens'] = e['max_tokens'];
    if (e.containsKey('stop')) {
      final stop = e['stop'];
      generationConfig['stopSequences'] = stop is List ? stop : [stop];
    }

    final body = <String, dynamic>{'contents': contents};
    if (sysText.isNotEmpty) body['systemInstruction'] = {'parts': [{'text': sysText}]};
    if (generationConfig.isNotEmpty) body['generationConfig'] = generationConfig;
    final tools = e['tools'];
    if (tools is List && tools.isNotEmpty) {
      body['tools'] = tools
          .where((t) => t is Map && t['type'] == 'function' && (t['function'] as Map?)?['name'] != null)
          .map((t) => {
                'functionDeclarations': [
                  {
                    'name': (t['function'] as Map)['name'],
                    'description': (t['function'] as Map?)?['description'],
                    'parameters': (t['function'] as Map?)?['parameters'],
                  }
                ],
              })
          .toList();
    }
    if (e.containsKey('tool_choice')) {
      body['toolConfig'] = {'functionCallingConfig': mapToolChoice(e['tool_choice'])};
    }

    return AdapterRequest(
      url,
      {'Content-Type': 'application/json'},
      jsonEncode(body),
    );
  }

  /// OpenAI 单条 message → Gemini content(角色/工具转换)。
  static Map<String, dynamic> _convertMessage(Map<String, dynamic> m) {
    if (m['role'] == 'tool') {
      return {
        'role': 'function',
        'parts': [
          {
            'functionResponse': {
              'name': m['name'] ?? m['tool_call_id'] ?? 'tool',
              'response': _safeParseOrObj(m['content']),
            }
          }
        ],
      };
    }
    final tcs = m['tool_calls'];
    if (m['role'] == 'assistant' && tcs is List && tcs.isNotEmpty) {
      return {
        'role': 'model',
        'parts': tcs
            .map((tc) => {
                  'functionCall': {
                    'name': (tc['function'] as Map?)?['name'] ?? '',
                    'args': _safeParseOrArgs((tc['function'] as Map?)?['arguments']),
                  }
                })
            .toList(),
      };
    }
    return {
      'role': m['role'] == 'assistant' ? 'model' : 'user',
      'parts': [{'text': m['content'] ?? ''}],
    };
  }

  @override
  StreamEvent? parseStreamLine(String line, String providerModel) {
    var data = line.trim();
    if (data.startsWith('data: ')) data = data.substring(6);
    if (data.isEmpty) return null;
    if (data == '[DONE]') return const StreamEvent(done: true);
    Map<String, dynamic> obj;
    try {
      obj = jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
    final candidate = (obj['candidates'] as List?)?.firstOrNull;
    if (candidate is! Map) return null;
    final parts = (candidate['content']?['parts'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final text = parts.map((p) => (p['text'] as String?) ?? '').join();

    final toolCallDeltas = parts
        .where((p) => p.containsKey('functionCall'))
        .toList()
        .asMap()
        .entries
        .map((e) => {
              'index': e.key,
              'id': 'call_${e.key}',
              'type': 'function',
              'function': {
                'name': (e.value['functionCall'] as Map)['name'],
                'arguments': jsonEncode((e.value['functionCall'] as Map?)?['args'] ?? {}),
              },
            })
        .toList();

    final delta = <String, dynamic>{'content': text};
    if (toolCallDeltas.isNotEmpty) delta['tool_calls'] = toolCallDeltas;

    final now = DateTime.now().millisecondsSinceEpoch;
    final chunk = LlmStreamChunk(
      id: 'gemini-$now',
      object: 'chat.completion.chunk',
      created: now ~/ 1000,
      model: (obj['modelVersion'] as String?) ?? providerModel,
      choices: [
        {
          'index': 0,
          'delta': delta,
          'finish_reason': mapFinishReason(candidate['finishReason']),
        }
      ],
    );

    LlmUsage? usage;
    final um = obj['usageMetadata'];
    if (um is Map) {
      final m = Map<String, dynamic>.from(um);
      usage = LlmUsage(
        promptTokens: (m['promptTokenCount'] as num?)?.toInt() ?? 0,
        completionTokens: (m['candidatesTokenCount'] as num?)?.toInt() ?? 0,
        totalTokens: (m['totalTokenCount'] as num?)?.toInt() ?? 0,
        extra: m,
      );
    }
    return StreamEvent(chunk: chunk, usage: usage);
  }

  /// Gemini finishReason → OpenAI finish_reason(上游 mapGeminiFinishReason)。
  static String? mapFinishReason(Object? reason) {
    if (reason == 'MAX_TOKENS') return 'length';
    if (reason == 'STOP') return 'stop';
    if (reason == 'SAFETY' ||
        reason == 'RECITATION' ||
        reason == 'BLOCKLIST' ||
        reason == 'PROHIBITED_CONTENT' ||
        reason == 'SPII') {
      return 'content_filter';
    }
    return null;
  }

  /// OpenAI tool_choice → Gemini functionCallingConfig(上游 mapGeminiToolChoice)。
  static Map<String, dynamic> mapToolChoice(Object? choice) {
    if (choice == 'auto' || choice == null) return {'mode': 'AUTO'};
    if (choice == 'any') return {'mode': 'ANY'};
    if (choice == 'none') return {'mode': 'NONE'};
    if (choice is Map && choice['type'] == 'function') {
      final name = (choice['function'] as Map?)?['name'];
      final allowed = name == null ? <String>[] : [name];
      return allowed.isEmpty ? {'mode': 'ANY'} : {'mode': 'ANY', 'allowedFunctionNames': allowed};
    }
    return {'mode': 'AUTO'};
  }

  static Object _safeParseOrObj(Object? content) {
    if (content is String) return _safeParseJson(content);
    return content ?? <String, dynamic>{};
  }

  static Object _safeParseOrArgs(Object? args) {
    if (args is String) return _safeParseJson(args);
    return args ?? <String, dynamic>{};
  }

  static Object _safeParseJson(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return s;
    }
  }
}
