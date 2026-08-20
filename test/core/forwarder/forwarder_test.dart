import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowing_water/core/forwarder/adapters/types.dart';
import 'package:flowing_water/core/forwarder/forwarder.dart';
import 'package:flowing_water/core/forwarder/model_mapping.dart';
import 'package:flowing_water/core/forwarder/stream_http.dart';
import 'package:flowing_water/core/relay/messages.dart';

/// forwarder 流式管线测试 —— 用假 StreamHttpFn 产预设 SSE,锁定移植契约:
/// 成功往返 / idle 超时 / 0-chunk / 非 SSE / upstream 错误码 / cancel 静默 /
/// vendor 不支持流式 / 无 usage 兜底 {0,0,0}。
void main() {
  const provider = ProviderMapping(
    endpoint: 'https://api.openai.com/v1',
    apiKey: 'sk-x',
    adapterType: AdapterType.openai, // 由 enum 直接构造省去 parseAdapterType
    supportsStream: true,
    providerModel: 'gpt-4o',
    inputPricePer1k: 1,
    outputPricePer1k: 1,
  );

  // 用 AdapterType enum 构造的等价 provider(parseAdapterType 链路在 mapping 测试覆盖)。
  ProviderMapping providerWith({
    bool? supportsStream,
    AdapterType? adapterType,
  }) =>
      ProviderMapping(
        endpoint: provider.endpoint,
        apiKey: provider.apiKey,
        adapterType: adapterType ?? provider.adapterType,
        supportsStream: supportsStream ?? provider.supportsStream,
        providerModel: provider.providerModel,
        inputPricePer1k: provider.inputPricePer1k,
        outputPricePer1k: provider.outputPricePer1k,
      );

  List<int> sse(String json) => utf8.encode('data: $json\n\n');

  StreamHttpFn fakeHttp({
    required int status,
    required String contentType,
    List<List<int>> chunks = const [],
    Object? error,
    Duration? firstByteDelay,
  }) {
    return ({required url, required headers, required body, required cancelToken}) async {
      final controller = StreamController<List<int>>();
      Future(() async {
        if (firstByteDelay != null) await Future.delayed(firstByteDelay);
        if (error != null) {
          controller.addError(error);
        } else {
          for (final c in chunks) {
            controller.add(c);
          }
        }
        await controller.close();
      });
      return UpstreamStreamedResponse(status, contentType, controller.stream);
    };
  }

  group('成功往返', () {
    test('chunk×2 + usage + [DONE] → onChunk×2 / onEnd(usage) / success', () async {
      final chunks = <LlmStreamChunk>[];
      LlmUsage? endUsage;
      final res = await forwardStreamRequest(
        provider: provider,
        request: LlmRequest(model: 'gpt-4o', messages: []),
        cancelToken: CancelToken(),
        streamHttp: fakeHttp(
          status: 200,
          contentType: 'text/event-stream',
          chunks: [
            sse('{"id":"x","object":"chat.completion.chunk","created":1,"model":"gpt-4o",'
                '"choices":[{"index":0,"delta":{"content":"Hi"},"finish_reason":null}]}'),
            sse('{"id":"x","object":"chat.completion.chunk","created":1,"model":"gpt-4o",'
                '"choices":[{"index":0,"delta":{"content":"!"},"finish_reason":null}]}'),
            sse('{"choices":[],"usage":{"prompt_tokens":10,"completion_tokens":5,'
                '"total_tokens":15}}'),
            sse('[DONE]'),
          ],
        ),
        callbacks: StreamCallbacks(
          onChunk: chunks.add,
          onEnd: (u) => endUsage = u,
          onError: (_, _) => fail('不应 onError'),
        ),
      );
      expect(res.success, isTrue);
      // 3 = 2 delta chunk + 1 usage 行的空 choices chunk(忠实上游:parseStreamLine
      // 对 usage 行也产 chunk,relay 容忍空 delta;chunkCount 不参与计费)。
      expect(chunks.length, 3);
      expect(chunks[0].choices.single['delta']['content'], 'Hi');
      expect(chunks[1].choices.single['delta']['content'], '!');
      expect(chunks[2].choices, isEmpty);
      expect(endUsage!.promptTokens, 10);
      expect(endUsage!.completionTokens, 5);
      expect(endUsage!.totalTokens, 15);
    });

    test('无 usage 兜底 {0,0,0}(防漏计 fallback)', () async {
      LlmUsage? endUsage;
      await forwardStreamRequest(
        provider: provider,
        request: LlmRequest(model: 'gpt-4o', messages: []),
        cancelToken: CancelToken(),
        streamHttp: fakeHttp(
          status: 200,
          contentType: 'text/event-stream',
          chunks: [
            sse('{"id":"x","object":"chat.completion.chunk","created":1,"model":"gpt-4o",'
                '"choices":[{"index":0,"delta":{"content":"x"},"finish_reason":null}]}'),
            sse('[DONE]'),
          ],
        ),
        callbacks: StreamCallbacks(
          onChunk: (_) {},
          onEnd: (u) => endUsage = u,
          onError: (_, _) => fail('不应 onError'),
        ),
      );
      expect(endUsage!.promptTokens, 0);
      expect(endUsage!.completionTokens, 0);
      expect(endUsage!.totalTokens, 0);
    });
  });

  test('0 chunk → onError(empty_stream)', () async {
    String? code;
    await forwardStreamRequest(
      provider: provider,
      request: LlmRequest(model: 'gpt-4o', messages: []),
      cancelToken: CancelToken(),
      streamHttp: fakeHttp(
        status: 200,
        contentType: 'text/event-stream',
        chunks: [sse('[DONE]')],
      ),
      callbacks: StreamCallbacks(
        onChunk: (_) => fail('不应 onChunk'),
        onEnd: (_) => fail('不应 onEnd'),
        onError: (c, _) => code = c,
      ),
    );
    expect(code, 'empty_stream');
  });

  test('非 SSE 响应 → onError(upstream_non_sse)', () async {
    String? code;
    await forwardStreamRequest(
      provider: provider,
      request: LlmRequest(model: 'gpt-4o', messages: []),
      cancelToken: CancelToken(),
      streamHttp: fakeHttp(
        status: 200,
        contentType: 'application/json',
        chunks: [utf8.encode('{"error":"not streaming"}')],
      ),
      callbacks: StreamCallbacks(
        onChunk: (_) {},
        onEnd: (_) {},
        onError: (c, _) => code = c,
      ),
    );
    expect(code, 'upstream_non_sse');
  });

  test('upstream 500 → onError(upstream_500)', () async {
    String? code;
    await forwardStreamRequest(
      provider: provider,
      request: LlmRequest(model: 'gpt-4o', messages: []),
      cancelToken: CancelToken(),
      streamHttp: fakeHttp(
        status: 500,
        contentType: 'text/plain',
        chunks: [utf8.encode('boom')],
      ),
      callbacks: StreamCallbacks(
        onChunk: (_) {},
        onEnd: (_) {},
        onError: (c, _) => code = c,
      ),
    );
    expect(code, 'upstream_500');
  });

  test('idle 超时(首字节延迟 > idleTimeout)→ onError(stream_idle)', () async {
    String? code;
    await forwardStreamRequest(
      provider: provider,
      request: LlmRequest(model: 'gpt-4o', messages: []),
      cancelToken: CancelToken(),
      idleTimeout: const Duration(milliseconds: 50),
      streamHttp: fakeHttp(
        status: 200,
        contentType: 'text/event-stream',
        firstByteDelay: const Duration(milliseconds: 200),
      ),
      callbacks: StreamCallbacks(
        onChunk: (_) {},
        onEnd: (_) {},
        onError: (c, _) => code = c,
      ),
    );
    expect(code, 'stream_idle');
  });

  test('外部 cancel → 静默返回(不 onError/onEnd)', () async {
    final token = CancelToken();
    token.cancel('client_disconnected');
    bool errored = false;
    bool ended = false;
    final res = await forwardStreamRequest(
      provider: provider,
      request: LlmRequest(model: 'gpt-4o', messages: []),
      cancelToken: token,
      streamHttp: fakeHttp(
        status: 200,
        contentType: 'text/event-stream',
        error: DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.cancel,
        ),
      ),
      callbacks: StreamCallbacks(
        onChunk: (_) {},
        onEnd: (_) => ended = true,
        onError: (_, _) => errored = true,
      ),
    );
    expect(res.success, isFalse);
    expect(errored, isFalse, reason: 'cancel 是正常取消,不回 error');
    expect(ended, isFalse);
  });

  test('vendor 不支持流式 → onError(unsupported_stream)', () async {
    String? code;
    await forwardStreamRequest(
      provider: providerWith(supportsStream: false),
      request: LlmRequest(model: 'gpt-4o', messages: []),
      cancelToken: CancelToken(),
      streamHttp: fakeHttp(status: 200, contentType: 'text/event-stream'),
      callbacks: StreamCallbacks(
        onChunk: (_) {},
        onEnd: (_) {},
        onError: (c, _) => code = c,
      ),
    );
    expect(code, 'unsupported_stream');
  });
}

