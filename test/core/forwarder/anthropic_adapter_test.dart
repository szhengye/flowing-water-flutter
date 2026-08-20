import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/forwarder/adapters/anthropic.dart';
import 'package:flowing_water/core/forwarder/adapters/types.dart';
import 'package:flowing_water/core/relay/messages.dart';

/// Anthropic 适配器测试 —— 锁定与 OpenAI 的差异:system 抽顶层、per-stream
/// tool_use 状态、事件流解析(text_delta/input_json_delta/thinking_delta/
/// message_delta usage/message_stop)。
void main() {
  group('buildRequest', () {
    test('system 抽到顶层,messages 不含 system;max_tokens 默认 4096', () {
      final built = AnthropicAdapter().buildRequest(
        providerEndpoint: 'https://api.anthropic.com/v1',
        providerApiKey: 'sk-ant',
        providerModel: 'claude-3',
        request: LlmRequest(model: 'claude', messages: [
          {'role': 'system', 'content': 'be nice'},
          {'role': 'user', 'content': 'hi'},
        ]),
        stream: true,
      );
      final body = jsonDecode(built.body) as Map<String, dynamic>;
      expect(body['system'], 'be nice');
      expect((body['messages'] as List).single['role'], 'user');
      expect(body['max_tokens'], 4096);
      expect(body['stream'], true);
    });

    test('headers x-api-key + anthropic-version;resolveEndpoint /v1→/messages', () {
      final built = AnthropicAdapter().buildRequest(
        providerEndpoint: 'https://api.anthropic.com/v1',
        providerApiKey: 'k',
        providerModel: 'm',
        request: LlmRequest(model: 'm', messages: []),
        stream: false,
      );
      expect(built.url, 'https://api.anthropic.com/v1/messages');
      expect(built.headers['x-api-key'], 'k');
      expect(built.headers['anthropic-version'], '2023-06-01');
      expect(built.headers.containsKey('Authorization'), isFalse);
    });

    test('stop → stop_sequences 数组化;max_tokens 显式覆盖默认', () {
      final built = AnthropicAdapter().buildRequest(
        providerEndpoint: 'https://x/v1',
        providerApiKey: 'k',
        providerModel: 'm',
        request: LlmRequest(model: 'm', messages: [], extra: {
          'max_tokens': 100,
          'stop': 'END',
        }),
        stream: false,
      );
      final body = jsonDecode(built.body) as Map<String, dynamic>;
      expect(body['max_tokens'], 100);
      expect(body['stop_sequences'], ['END']);
    });
  });

  group('parseStreamLine 事件流', () {
    test('message_start → delta.role=assistant + model 透传', () {
      final ev = AnthropicAdapter().parseStreamLine(
        'data: {"type":"message_start","message":{"id":"msg1","model":"claude-3"}}',
        'claude-3',
      )!;
      expect(ev.chunk!.choices.single['delta']['role'], 'assistant');
      expect(ev.chunk!.model, 'claude-3');
    });

    test('text_delta → delta.content', () {
      final ev = AnthropicAdapter().parseStreamLine(
        'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"Hi"}}',
        'claude-3',
      )!;
      expect(ev.chunk!.choices.single['delta']['content'], 'Hi');
    });

    test('thinking_delta → reasoning_content(扩展思维)', () {
      final ev = AnthropicAdapter().parseStreamLine(
        'data: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"hm"}}',
        'claude-3',
      )!;
      expect(ev.chunk!.choices.single['delta']['reasoning_content'], 'hm');
    });

    test('message_delta usage(completion=output_tokens)+stop_reason 映射 stop', () {
      final ev = AnthropicAdapter().parseStreamLine(
        'data: {"type":"message_delta","usage":{"output_tokens":42},"delta":{"stop_reason":"end_turn"}}',
        'claude-3',
      )!;
      expect(ev.usage!.completionTokens, 42);
      expect(ev.chunk!.choices.single['finish_reason'], 'stop');
    });

    test('message_stop → done', () {
      expect(
        AnthropicAdapter().parseStreamLine('data: {"type":"message_stop"}', 'm')!
            .done,
        isTrue,
      );
    });

    test('非 data 行 → null', () {
      expect(AnthropicAdapter().parseStreamLine('event: ping', 'm'), isNull);
    });
  });

  group('per-stream tool_use 状态(content_block_stop 后 stray delta drop)', () {
    test('start→delta→stop→stray delta drop(隔离证据)', () {
      final a = AnthropicAdapter();
      final start = a.parseStreamLine(
        'data: {"type":"content_block_start","index":2,"content_block":'
        '{"type":"tool_use","id":"tu1","name":"get_weather"}}',
        'm',
      )!;
      expect(start.chunk!.choices.single['delta']['tool_calls'].single['function']['name'],
          'get_weather');

      final delta = a.parseStreamLine(
        'data: {"type":"content_block_delta","index":2,"delta":'
        '{"type":"input_json_delta","partial_json":"ab"}}',
        'm',
      )!;
      expect(delta.chunk!.choices.single['delta']['tool_calls'].single['function']['arguments'],
          'ab');

      // stop 清状态,不发 chunk。
      expect(
        a.parseStreamLine('data: {"type":"content_block_stop","index":2}', 'm'),
        isNull,
      );
      // stop 后同 index 的 stray input_json_delta → drop(状态已清)。
      expect(
        a.parseStreamLine(
          'data: {"type":"content_block_delta","index":2,"delta":'
          '{"type":"input_json_delta","partial_json":"x"}}',
          'm',
        ),
        isNull,
      );
    });
  });

  test('type=anthropic', () {
    expect(AnthropicAdapter().type, AdapterType.anthropic);
  });

  test('stop_reason 映射全表', () {
    expect(AnthropicAdapter.mapStopReason('max_tokens'), 'length');
    expect(AnthropicAdapter.mapStopReason('tool_use'), 'tool_calls');
    expect(AnthropicAdapter.mapStopReason('refusal'), 'content_filter');
    expect(AnthropicAdapter.mapStopReason('unknown'), isNull);
  });
}
