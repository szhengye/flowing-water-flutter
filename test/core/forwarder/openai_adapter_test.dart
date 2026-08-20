import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/forwarder/adapters/openai.dart';
import 'package:flowing_water/core/forwarder/adapters/types.dart';
import 'package:flowing_water/core/relay/messages.dart';

/// OpenAI 适配器测试 —— 锁定 web3-api openai.ts 的移植契约。
///
/// 重点:stream_options.include_usage 的注入/尊重(漏注会导致 relay 漏计)、
/// delta 透传(upstream wins)、parseStreamLine 一行可同时产 chunk + usage。
void main() {
  const adapter = OpenAIAdapter(); // 无状态,单实例安全(Anthropic 才需 per-stream)

  group('resolveEndpoint(base URL 自动补 /chat/completions)', () {
    test('/v1 结尾补全', () {
      expect(
        OpenAIAdapter.resolveEndpoint('https://api.openai.com/v1'),
        'https://api.openai.com/v1/chat/completions',
      );
    });
    test('带 trailing / 先修剪再判断', () {
      expect(
        OpenAIAdapter.resolveEndpoint('https://api.openai.com/v1/'),
        'https://api.openai.com/v1/chat/completions',
      );
    });
    test('已是完整 endpoint 路径不重复补', () {
      expect(
        OpenAIAdapter.resolveEndpoint('https://x.com/v1/chat/completions'),
        'https://x.com/v1/chat/completions',
      );
    });
  });

  group('buildRequest', () {
    test('providerModel 覆盖 relayModel,透传 messages/temperature,注入 include_usage', () {
      final req = LlmRequest(
        model: 'relay-gpt4o',
        messages: [
          {'role': 'user', 'content': 'hi'}
        ],
        extra: {'temperature': 0.7},
      );
      final built = adapter.buildRequest(
        providerEndpoint: 'https://api.openai.com/v1',
        providerApiKey: 'sk-x',
        providerModel: 'gpt-4o',
        request: req,
        stream: true,
      );
      final body = jsonDecode(built.body) as Map<String, dynamic>;
      expect(body['model'], 'gpt-4o', reason: 'providerModel 必须覆盖 relayModel');
      expect((body['messages'] as List).single['content'], 'hi');
      expect(body['temperature'], 0.7);
      expect(body['stream'], true);
      expect(body['stream_options']['include_usage'], true,
          reason: '流式须注入 include_usage,否则兼容网关可能不发 usage → 漏计');
      expect(built.headers['Authorization'], 'Bearer sk-x');
      expect(built.headers['Content-Type'], 'application/json');
      expect(built.url, 'https://api.openai.com/v1/chat/completions');
    });

    test('非流式不注入 stream_options', () {
      final built = adapter.buildRequest(
        providerEndpoint: 'https://api.openai.com/v1',
        providerApiKey: 'sk',
        providerModel: 'gpt-4o',
        request: LlmRequest(model: 'm', messages: []),
        stream: false,
      );
      expect(
        (jsonDecode(built.body) as Map).containsKey('stream_options'),
        isFalse,
      );
    });

    test('调用方显式 include_usage:false 被尊重(不强制覆写)', () {
      final req = LlmRequest(
        model: 'm',
        messages: [],
        extra: {
          'stream_options': {'include_usage': false}
        },
      );
      final built = adapter.buildRequest(
        providerEndpoint: 'https://api.openai.com/v1',
        providerApiKey: 'sk',
        providerModel: 'gpt-4o',
        request: req,
        stream: true,
      );
      final so =
          (jsonDecode(built.body) as Map)['stream_options'] as Map<String, dynamic>;
      expect(so['include_usage'], false);
    });
  });

  group('parseStreamLine', () {
    test('非 data 行(注释/心跳)→ null', () {
      expect(adapter.parseStreamLine(': openai comment', 'gpt-4o'), isNull);
      expect(adapter.parseStreamLine('', 'gpt-4o'), isNull);
    });

    test('data: [DONE] → done 事件', () {
      expect(adapter.parseStreamLine('data: [DONE]', 'gpt-4o')!.done, isTrue);
    });

    test('delta chunk 透传 content', () {
      final ev = adapter.parseStreamLine(
        'data: {"id":"x","object":"chat.completion.chunk","created":1,'
            '"model":"gpt-4o","choices":[{"index":0,"delta":{"content":"Hi"},'
            '"finish_reason":null}]}',
        'gpt-4o',
      )!;
      expect(ev.chunk, isNotNull);
      expect(ev.chunk!.id, 'x');
      expect(ev.chunk!.choices.single['delta']['content'], 'Hi');
      expect(ev.usage, isNull);
    });

    test('一行同时产 chunk + usage(OpenAI 末尾 usage chunk)', () {
      final ev = adapter.parseStreamLine(
        'data: {"id":"x","object":"chat.completion.chunk","created":1,'
            '"model":"gpt-4o","choices":[],'
            '"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}',
        'gpt-4o',
      )!;
      expect(ev.chunk, isNotNull);
      expect(ev.usage, isNotNull);
      expect(ev.usage!.promptTokens, 10);
      expect(ev.usage!.completionTokens, 5);
      expect(ev.usage!.totalTokens, 15);
    });

    test('usage 子字段(prompt_tokens_details)透传进 extra', () {
      final ev = adapter.parseStreamLine(
        'data: {"choices":[],"usage":{"prompt_tokens":1,"completion_tokens":1,'
            '"total_tokens":2,"prompt_tokens_details":{"cached_tokens":3}}}',
        'gpt-4o',
      )!;
      expect(ev.usage!.extra['prompt_tokens_details']['cached_tokens'], 3);
    });

    test('畸形 data 行 → null(不打掉整条流)', () {
      expect(adapter.parseStreamLine('data: {bad json', 'gpt-4o'), isNull);
    });

    test('缺失字段用安全默认(id/created/object/model)', () {
      final ev = adapter.parseStreamLine(
        'data: {"choices":[{"index":0,"delta":{}}]}',
        'fallback-model',
      )!;
      expect(ev.chunk!.model, 'fallback-model');
      expect(ev.chunk!.object, 'chat.completion.chunk');
      expect(ev.chunk!.choices.single['delta']['content'], '',
          reason: '缺省 content 为空串');
    });
  });

  test('AdapterType 对齐 provider_info.adapter_type', () {
    expect(adapter.type, AdapterType.openai);
  });
}
