import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/db/database.dart';
import '../../core/forwarder/adapters/factory.dart';
import '../../core/forwarder/model_mapping.dart';
import '../../core/forwarder/stream_http.dart';
import '../../core/relay/messages.dart';

/// 连通性探测结果。
class ProbeResult {
  const ProbeResult({required this.ok, required this.message});
  final bool ok;
  final String message;
}

/// 用**真实转发路径**探测 vendor 连通性:构 minimal 流式请求 → 验 200 + SSE。
///
/// 复用 [makeAdapter] + [ProviderAdapter.buildRequest] + [StreamHttpFn],无需每厂
/// 定制探测逻辑(与 forwarder 同一条代码路径,探测通过≈转发能跑)。200 且
/// Content-Type 含 text/event-stream → 可达;否则带错误信息。Gemini 走 JSON 流,
/// Content-Type 非 SSE → 会判"非流式",探测用 streamGenerateContent 仍能到 200。
Future<ProbeResult> probeVendor({
  required ProviderLlmVendorRow vendor,
  required String providerModel,
  StreamHttpFn? streamHttp,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final http = streamHttp ?? dioStreamHttp(Dio());
  final adapter = makeAdapter(parseAdapterType(vendor.adapterType));
  final built = adapter.buildRequest(
    providerEndpoint: vendor.endpoint,
    providerApiKey: vendor.apiKey,
    providerModel: providerModel,
    request: LlmRequest(
      model: providerModel,
      messages: [
        {'role': 'user', 'content': 'hi'}
      ],
      extra: {'max_tokens': 1},
    ),
    stream: true,
  );
  try {
    final res = await http(
      url: built.url,
      headers: built.headers,
      body: built.body,
      cancelToken: CancelToken(),
    ).timeout(timeout);
    if (res.statusCode != 200) {
      return ProbeResult(ok: false, message: 'HTTP ${res.statusCode}');
    }
    if (!res.contentType.toLowerCase().contains('text/event-stream')) {
      return ProbeResult(ok: false, message: '非流式(${res.contentType})');
    }
    return const ProbeResult(ok: true, message: '可达(200 + SSE)');
  } on DioException catch (e) {
    return ProbeResult(ok: false, message: e.message ?? e.type.name);
  } catch (e) {
    return ProbeResult(ok: false, message: '$e');
  }
}

/// 解析 vendor.vendorModels(JSON array)首个模型名;空/畸形 → null。
String? firstVendorModel(String vendorModelsJson) {
  try {
    final list = jsonDecode(vendorModelsJson);
    if (list is List && list.isNotEmpty) return list.first.toString();
  } catch (_) {}
  return null;
}
