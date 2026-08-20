import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/forwarder/adapters/gemini.dart';
import 'package:flowing_water/core/forwarder/adapters/types.dart';
import 'package:flowing_water/core/relay/messages.dart';

/// Gemini 适配器测试 —— 锁定与 OpenAI 的差异:URL :streamGenerateContent?key=、
/// OpenAI messages→Gemini contents 角色映射、原始 JSON 流解析(非 SSE)。
void main() {
  group('buildRequest', () {
    test('url :streamGenerateContent?key= + header 仅 Content-Type(key 不入 header)', () {
      final built = const GeminiAdapter().buildRequest(
        providerEndpoint: 'https://generativelanguage.googleapis.com',
        providerApiKey: 'GKEY',
        providerModel: 'gemini-1.5-pro',
        request: LlmRequest(model: 'm', messages: [
          {'role': 'user', 'content': 'hi'}
        ]),
        stream: true,
      );
      expect(
        built.url,
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-1.5-pro:streamGenerateContent?key=GKEY',
      );
      expect(built.headers.keys.toSet(), {'Content-Type'});
    });

    test('system→systemInstruction;user→user;assistant→model', () {
      final built = const GeminiAdapter().buildRequest(
        providerEndpoint: 'https://x',
        providerApiKey: 'k',
        providerModel: 'm',
        request: LlmRequest(model: 'm', messages: [
          {'role': 'system', 'content': 'sys'},
          {'role': 'user', 'content': 'u'},
          {'role': 'assistant', 'content': 'a'},
        ]),
        stream: false,
      );
      final body = jsonDecode(built.body) as Map<String, dynamic>;
      expect(body['systemInstruction']['parts'].single['text'], 'sys');
      final roles = (body['contents'] as List).map((c) => c['role']).toList();
      expect(roles, ['user', 'model']);
    });

    test('generationConfig(maxOutputTokens)+ tools(functionDeclarations)', () {
      final built = const GeminiAdapter().buildRequest(
        providerEndpoint: 'https://x',
        providerApiKey: 'k',
        providerModel: 'm',
        request: LlmRequest(model: 'm', messages: [], extra: {
          'max_tokens': 100,
          'tools': [
            {
              'type': 'function',
              'function': {'name': 'f', 'description': 'd', 'parameters': {}}
            }
          ],
        }),
        stream: false,
      );
      final body = jsonDecode(built.body) as Map<String, dynamic>;
      expect(body['generationConfig']['maxOutputTokens'], 100);
      expect(body['tools'].single['functionDeclarations'].single['name'], 'f');
    });
  });

  group('parseStreamLine(原始 JSON 流,非 SSE)', () {
    test('text + finishReason 映射 + usageMetadata', () {
      final ev = const GeminiAdapter().parseStreamLine(
        '{"candidates":[{"content":{"parts":[{"text":"Hi"}],"role":"model"},'
        '"finishReason":"STOP"}],"usageMetadata":{"promptTokenCount":5,'
        '"candidatesTokenCount":3,"totalTokenCount":8}}',
        'gemini-1.5-pro',
      )!;
      expect(ev.chunk!.choices.single['delta']['content'], 'Hi');
      expect(ev.chunk!.choices.single['finish_reason'], 'stop');
      expect(ev.usage!.completionTokens, 3);
      expect(ev.usage!.totalTokens, 8);
    });

    test('[DONE]→done(兼容 data: 前缀剥离)', () {
      expect(const GeminiAdapter().parseStreamLine('data: [DONE]', 'm')!.done,
          isTrue);
    });

    test('无 candidate → null', () {
      expect(const GeminiAdapter().parseStreamLine('{"usageMetadata":{}}', 'm'),
          isNull);
    });

    test('畸形 JSON → null', () {
      expect(const GeminiAdapter().parseStreamLine('{bad', 'm'), isNull);
    });
  });

  test('mapFinishReason 全表', () {
    expect(GeminiAdapter.mapFinishReason('MAX_TOKENS'), 'length');
    expect(GeminiAdapter.mapFinishReason('SAFETY'), 'content_filter');
    expect(GeminiAdapter.mapFinishReason('STOP'), 'stop');
    expect(GeminiAdapter.mapFinishReason('OTHER'), isNull);
  });

  test('type=gemini', () {
    expect(const GeminiAdapter().type, AdapterType.gemini);
  });
}
