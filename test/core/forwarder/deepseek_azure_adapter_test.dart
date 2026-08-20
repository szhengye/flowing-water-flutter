import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/forwarder/adapters/azure_openai.dart';
import 'package:flowing_water/core/forwarder/adapters/deepseek.dart';
import 'package:flowing_water/core/forwarder/adapters/types.dart';
import 'package:flowing_water/core/relay/messages.dart';

/// DeepSeek / Azure 适配器测试 —— 锁定与 OpenAI 的差异点委托契约。
/// DeepSeek:纯委托(Bearer + endpoint 透传)。Azure:buildRequest 自定义(部署 URL
/// + api-key header + api-version),解析委托 OpenAI。
void main() {
  group('DeepSeekAdapter(委托 OpenAI)', () {
    test('type=deepseek', () {
      expect(const DeepSeekAdapter().type, AdapterType.deepseek);
    });

    test('buildRequest 用 OpenAI 形态(Bearer + resolveEndpoint)', () {
      final built = const DeepSeekAdapter().buildRequest(
        providerEndpoint: 'https://api.deepseek.com/v1',
        providerApiKey: 'sk-ds',
        providerModel: 'deepseek-chat',
        request: LlmRequest(model: 'm', messages: []),
        stream: true,
      );
      expect(built.url, 'https://api.deepseek.com/v1/chat/completions');
      expect(built.headers['Authorization'], 'Bearer sk-ds');
      expect(
        (jsonDecode(built.body) as Map)['stream_options']['include_usage'],
        true,
      );
    });

    test('parseStreamLine 委托 OpenAI([DONE]→done)', () {
      expect(const DeepSeekAdapter().parseStreamLine('data: [DONE]', 'd')!.done,
          isTrue);
    });
  });

  group('AzureOpenAIAdapter(部署 URL + api-key,解析委托)', () {
    test('buildRequest:url=.../openai/deployments/{model}/chat/completions?api-version=默认', () {
      final built = const AzureOpenAIAdapter().buildRequest(
        providerEndpoint: 'https://myacct.openai.azure.com',
        providerApiKey: 'az-key',
        providerModel: 'gpt-4o-deploy',
        request: LlmRequest(model: 'm', messages: []),
        stream: true,
      );
      expect(
        built.url,
        'https://myacct.openai.azure.com/openai/deployments/'
        'gpt-4o-deploy/chat/completions?api-version=2024-02-15-preview',
      );
    });

    test('headers 用 api-key(非 Bearer)', () {
      final built = const AzureOpenAIAdapter().buildRequest(
        providerEndpoint: 'https://x.azure.com',
        providerApiKey: 'az-key',
        providerModel: 'd',
        request: LlmRequest(model: 'm', messages: []),
        stream: false,
      );
      expect(built.headers['api-key'], 'az-key');
      expect(built.headers.containsKey('Authorization'), isFalse);
    });

    test('stream_options.include_usage 注入(与 openai 同款,Azure 不委托 buildRequest)', () {
      final built = const AzureOpenAIAdapter().buildRequest(
        providerEndpoint: 'https://x.azure.com',
        providerApiKey: 'k',
        providerModel: 'd',
        request: LlmRequest(model: 'm', messages: []),
        stream: true,
      );
      expect(
        (jsonDecode(built.body) as Map)['stream_options']['include_usage'],
        true,
      );
    });

    test('api-version 从 endpoint 的 ?api-version= 提取(覆盖默认)', () {
      final built = const AzureOpenAIAdapter().buildRequest(
        providerEndpoint: 'https://x.azure.com?api-version=2024-08-01-preview',
        providerApiKey: 'k',
        providerModel: 'd',
        request: LlmRequest(model: 'm', messages: []),
        stream: false,
      );
      expect(built.url, contains('api-version=2024-08-01-preview'));
    });

    test('parseStreamLine 委托 OpenAI(delta 透传)', () {
      final ev = const AzureOpenAIAdapter().parseStreamLine(
        'data: {"choices":[{"index":0,"delta":{"content":"Hi"},"finish_reason":null}]}',
        'd',
      )!;
      expect(ev.chunk!.choices.single['delta']['content'], 'Hi');
    });
  });
}
