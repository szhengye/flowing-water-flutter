import 'package:dio/dio.dart' show CancelToken;

import '../db/provider_log_dao.dart';
import '../relay/messages.dart';
import 'forwarder.dart';
import 'model_mapping.dart';
import 'stream_http.dart';

/// 桥接 relay WS ↔ forwarder,管取消 + provider_log 计费插桩(姊妹 09 §5)。
///
/// 在 [NodeService._start] 里构造(client 已建,`send = client.send` 自然可得,避免
/// Riverpod 循环依赖)。生命周期:
/// - `llm_request` → [handleLlmRequest]:解析 mapping → insert pending → 转发 →
///   onChunk 即时回吐 chunk;结束在主流程(await forwardStreamRequest 返回后)落库
///   + 回吐 end/error(保证 DAO 操作可 await,而非 fire-and-forget)。
/// - `llm_stream_cancel` → [handleStreamCancel]:cancel 在飞流的 CancelToken → dio
///   中止 → forwarder 静默返回(provider_log 留 pending,与上游一致)。
/// - WS 断开 → [abortAll]:中止所有在飞流(防孤立流挂在已死 WS 上)。
///
/// `providerSignature` 恒 `""`(01:结算锚链上,forwarder 无需签名)。
class StreamDispatcher {
  StreamDispatcher({
    required this.send,
    required this.dao,
    required this.resolveMapping,
    required this.streamHttp,
  });

  /// 回吐出站消息到 relay(WsClient.send,握手后有效)。
  final void Function(RelayMessage) send;
  final ProviderLogDao dao;
  final Future<ProviderMapping?> Function(String relayModel) resolveMapping;
  final StreamHttpFn streamHttp;

  final Map<String, CancelToken> _active = {};

  Future<void> handleLlmRequest(LlmRequestMessage msg) async {
    final requestId = msg.requestId;
    final mapping = await resolveMapping(msg.request.model);
    if (mapping == null) {
      final errMsg = 'No model mapping for ${msg.request.model}';
      await dao.failRecord(requestId: requestId, errorMessage: errMsg);
      send(LlmErrorMessage(requestId: requestId, code: 'no_mapping', message: errMsg));
      return;
    }

    final token = CancelToken();
    _active[requestId] = token;
    await dao.insertRecord(
      requestId: requestId,
      modelName: msg.request.model,
      inputPricePer1k: mapping.inputPricePer1k,
      outputPricePer1k: mapping.outputPricePer1k,
    );
    final sw = Stopwatch()..start();
    LlmUsage? endUsage;
    String? errCode;
    String? errMsg;

    try {
      await forwardStreamRequest(
        provider: mapping,
        request: msg.request,
        cancelToken: token,
        streamHttp: streamHttp,
        callbacks: StreamCallbacks(
          onChunk: (c) => send(LlmStreamChunkMessage(requestId: requestId, chunk: c)),
          onEnd: (u) => endUsage = u,
          onError: (code, m) {
            errCode = code;
            errMsg = m;
          },
        ),
      );

      if (endUsage != null) {
        final amount = ProviderLogDao.computeAmount(
          mapping.inputPricePer1k,
          mapping.outputPricePer1k,
          endUsage!.promptTokens,
          endUsage!.completionTokens,
        );
        await dao.completeRecord(
          requestId: requestId,
          promptTokens: endUsage!.promptTokens,
          completionTokens: endUsage!.completionTokens,
          amount: amount,
          latencyMs: sw.elapsedMilliseconds,
        );
        send(LlmStreamEndMessage(
          requestId: requestId,
          usage: endUsage!,
          providerSignature: '',
        ));
      } else if (errCode != null) {
        await dao.failRecord(
          requestId: requestId,
          errorMessage: '$errCode: $errMsg',
        );
        send(LlmErrorMessage(
          requestId: requestId,
          code: errCode!,
          message: errMsg ?? '',
        ));
      }
      // outcome.success==false 且无 end/error → cancel/abort:静默,provider_log 留 pending。
    } finally {
      _active.remove(requestId);
    }
  }

  /// 中转站取消在飞流 → CancelToken.cancel → dio 中止 → forwarder 静默返回。
  void handleStreamCancel(String requestId) => _active[requestId]?.cancel();

  /// WS 断开/重连前调:中止所有在飞流(上游 abortAllStreams)。
  void abortAll() {
    for (final t in _active.values) {
      t.cancel();
    }
    _active.clear();
  }

  bool get hasActive => _active.isNotEmpty;
}
