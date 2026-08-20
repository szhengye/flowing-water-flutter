import 'package:dio/dio.dart';

/// 上游流式 HTTP 响应的窄抽象(forwarder 只关心三件事:状态码、Content-Type、字节流)。
///
/// 把 dio 粘合从 forwarder 核心逻辑里剥出来:forwarder 接收一个 [StreamHttpFn] 注入,
/// 测试用假实现产预设 SSE 字节流;生产用 [dioStreamHttp] 包装真实 dio。这让 idle 超时、
/// 逐行解析、usage 累积、cancel 静默等核心语义可单测,不被 dio mock 细节拖累。
class UpstreamStreamedResponse {
  const UpstreamStreamedResponse(this.statusCode, this.contentType, this.body);
  final int statusCode;
  final String contentType;
  final Stream<List<int>> body;
}

typedef StreamHttpFn = Future<UpstreamStreamedResponse> Function({
  required String url,
  required Map<String, String> headers,
  required String body,
  required CancelToken cancelToken,
});

/// 默认 dio 流式实现(validateStatus 全放行 —— 4xx/5xx 由 forwarder 按 status 判定,
/// 不让 dio 抛;responseType.stream 拿原始字节流)。
StreamHttpFn dioStreamHttp(Dio dio) {
  return ({required url, required headers, required body, required cancelToken}) async {
    final res = await dio.postUri(
      Uri.parse(url),
      data: body,
      options: Options(
        headers: headers,
        responseType: ResponseType.stream,
        validateStatus: (_) => true,
      ),
      cancelToken: cancelToken,
    );
    final responseBody = res.data as ResponseBody;
    return UpstreamStreamedResponse(
      res.statusCode ?? 0,
      res.headers.value('content-type') ?? '',
      responseBody.stream,
    );
  };
}
