import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' show CancelToken;

import '../log/node_logger.dart';
import '../relay/messages.dart';
import 'adapters/factory.dart';
import 'adapters/types.dart';
import 'model_mapping.dart';
import 'stream_http.dart';

/// 流式转发的三个回调(对齐上游 StreamCallbacks)。onError 带 code + message,
/// 直接映射到 `llm_error{requestId, code, message}`(上游 onError 只传 string,
/// 这里拆出 code 便于下游分类,如 upstream_500 / upstream_non_sse / stream_idle)。
class StreamCallbacks {
  const StreamCallbacks({
    required this.onChunk,
    required this.onEnd,
    required this.onError,
  });
  final void Function(LlmStreamChunk chunk) onChunk;
  final void Function(LlmUsage usage) onEnd;
  final void Function(String code, String message) onError;
}

class ForwardOutcome {
  const ForwardOutcome({required this.success, required this.latencyMs});
  final bool success;
  final int latencyMs;
}

const int _kNewline = 10; // '\n'

/// 端到端流式转发:relay `llm_request` → 上游 LLM → 流式 chunk × N → `llm_stream_end`。
///
/// 逐行移植上游 `forwardStreamRequest` 关键语义:
/// - vendor 假流式检测:200 + 非 `text/event-stream` → onError(upstream_non_sse)。
/// - 30s idle 超时(每个 chunk 重置 Timer,非 dio.receiveTimeout —— 后者是首字节/总时长,
///   不匹配「无新数据」语义)。
/// - usage 取最后报告值(prompt/completion 各取 >0 的;total=prompt+completion);无 usage
///   兜底 {0,0,0}(与上游一致,relay 漏计由 09 §8 的 warn 暴露)。
/// - 0 chunk → onError(empty_stream);abort(外部 cancel)静默返回,不 onError。
///
/// [streamHttp] 注入便于测试;生产用 [dioStreamHttp]。[idleTimeout] 注入便于测试。
Future<ForwardOutcome> forwardStreamRequest({
  required ProviderMapping provider,
  required LlmRequest request,
  required StreamCallbacks callbacks,
  required CancelToken cancelToken,
  required StreamHttpFn streamHttp,
  Duration idleTimeout = const Duration(seconds: 30),
}) async {
  final sw = Stopwatch()..start();

  if (!provider.supportsStream) {
    callbacks.onError('unsupported_stream', 'vendor does not support streaming');
    return ForwardOutcome(success: false, latencyMs: sw.elapsedMilliseconds);
  }

  final adapter = makeAdapter(provider.adapterType);
  final built = adapter.buildRequest(
    providerEndpoint: provider.endpoint,
    providerApiKey: provider.apiKey,
    providerModel: provider.providerModel,
    request: request,
    stream: true,
  );

  final res = await streamHttp(
    url: built.url,
    headers: built.headers,
    body: built.body,
    cancelToken: cancelToken,
  );

  if (res.statusCode != 200) {
    final body = await _drainString(res.body);
    callbacks.onError('upstream_${res.statusCode}', _clip(body));
    return ForwardOutcome(success: false, latencyMs: sw.elapsedMilliseconds);
  }
  if (!res.contentType.toLowerCase().contains('text/event-stream')) {
    final body = await _drainString(res.body);
    callbacks.onError('upstream_non_sse', '${res.contentType}: ${_clip(body)}');
    return ForwardOutcome(success: false, latencyMs: sw.elapsedMilliseconds);
  }

  return _consumeStream(
    body: res.body,
    adapter: adapter,
    providerModel: provider.providerModel,
    callbacks: callbacks,
    cancelToken: cancelToken,
    idleTimeout: idleTimeout,
    elapsed: () => sw.elapsedMilliseconds,
  );
}

Future<ForwardOutcome> _consumeStream({
  required Stream<List<int>> body,
  required ProviderAdapter adapter,
  required String providerModel,
  required StreamCallbacks callbacks,
  required CancelToken cancelToken,
  required Duration idleTimeout,
  required int Function() elapsed,
}) async {
  final buffer = <int>[];
  int promptTokens = 0;
  int completionTokens = 0;
  int totalTokens = 0;
  bool usageReported = false;
  int chunkCount = 0;
  bool idleTimedOut = false;
  bool doneSeen = false;

  void processLine(String line) {
    final event = adapter.parseStreamLine(line, providerModel);
    if (event == null) return;
    if (event.error != null) {
      callbacks.onError('adapter_error', event.error!);
      return;
    }
    if (event.done) {
      doneSeen = true;
      return;
    }
    if (event.chunk != null) {
      chunkCount++;
      callbacks.onChunk(event.chunk!);
    }
    if (event.usage != null) {
      final u = event.usage!;
      if (u.promptTokens > 0) promptTokens = u.promptTokens;
      if (u.completionTokens > 0) completionTokens = u.completionTokens;
      totalTokens = promptTokens + completionTokens;
      usageReported = true;
    }
  }

  final completer = Completer<void>();
  late StreamSubscription<List<int>> sub;
  Timer? idleTimer;

  void armIdle() {
    idleTimer?.cancel();
    idleTimer = Timer(idleTimeout, () {
      idleTimedOut = true;
      idleTimer?.cancel();
      sub.cancel(); // 中止读取
      if (!completer.isCompleted) completer.complete(); // 解除 await(按 idle 处理)
    });
  }

  sub = body.listen(
    (data) {
      if (completer.isCompleted) return;
      armIdle();
      buffer.addAll(data);
      var nl = buffer.indexOf(_kNewline);
      while (nl >= 0) {
        final line = utf8.decode(buffer.sublist(0, nl), allowMalformed: true);
        buffer.removeRange(0, nl + 1);
        processLine(line);
        if (doneSeen || completer.isCompleted) {
          idleTimer?.cancel();
          return;
        }
        nl = buffer.indexOf(_kNewline);
      }
    },
    onError: (Object e) {
      idleTimer?.cancel();
      if (!completer.isCompleted) completer.completeError(e);
    },
    onDone: () {
      idleTimer?.cancel();
      if (completer.isCompleted) return;
      if (buffer.isNotEmpty) {
        processLine(utf8.decode(buffer, allowMalformed: true));
        buffer.clear();
      }
      completer.complete();
    },
    cancelOnError: true,
  );
  armIdle();

  try {
    await completer.future;
  } catch (e) {
    idleTimer?.cancel();
    // 外部取消(cancelToken)→ 静默返回;idle 由 timer 分支处理(completer.complete)。
    if (cancelToken.isCancelled) {
      return ForwardOutcome(success: false, latencyMs: elapsed());
    }
    nodeLog.error('forwarder stream_read_failed', e);
    callbacks.onError('stream_read_failed', '$e');
    return ForwardOutcome(success: false, latencyMs: elapsed());
  } finally {
    idleTimer?.cancel();
  }

  if (idleTimedOut) {
    callbacks.onError('stream_idle', 'no data for ${idleTimeout.inMilliseconds}ms');
    return ForwardOutcome(success: false, latencyMs: elapsed());
  }
  if (chunkCount == 0) {
    callbacks.onError('empty_stream', 'stream produced 0 chunks');
    return ForwardOutcome(success: false, latencyMs: elapsed());
  }
  callbacks.onEnd(LlmUsage(
    promptTokens: usageReported ? promptTokens : 0,
    completionTokens: usageReported ? completionTokens : 0,
    totalTokens: usageReported ? totalTokens : 0,
  ));
  return ForwardOutcome(success: true, latencyMs: elapsed());
}

String _clip(String s) => s.length <= 200 ? s : s.substring(0, 200);

Future<String> _drainString(Stream<List<int>> s) async {
  final buf = <int>[];
  await for (final c in s) {
    buf.addAll(c);
  }
  return utf8.decode(buf, allowMalformed: true);
}
