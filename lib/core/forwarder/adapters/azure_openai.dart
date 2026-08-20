import 'dart:convert';

import '../../relay/messages.dart';
import 'openai.dart';
import 'types.dart';

/// Azure OpenAI 适配器 —— 逐行移植 web3-api azure_openai.ts。
///
/// 与 [OpenAIAdapter] 的差异:**仅 buildRequest 自定义**(部署 URL
/// `/openai/deployments/{model}/chat/completions?api-version=...` + `api-key` header
/// 而非 Bearer);解析委托 OpenAI(stream_options 注入同样在本地做 —— 上游注释明
/// 确 Azure 不委托 buildRequest)。
class AzureOpenAIAdapter implements ProviderAdapter {
  const AzureOpenAIAdapter();

  static const _defaultApiVersion = '2024-02-15-preview';

  @override
  AdapterType get type => AdapterType.azureOpenai;

  @override
  AdapterRequest buildRequest({
    required String providerEndpoint,
    required String providerApiKey,
    required String providerModel,
    required LlmRequest request,
    required bool stream,
  }) {
    final base = providerEndpoint.replaceAll(RegExp(r'/+$'), '');
    final deployment = Uri.encodeComponent(providerModel);
    final apiVersion = Uri.encodeComponent(
      _extractApiVersion(providerEndpoint) ?? _defaultApiVersion,
    );
    final url =
        '$base/openai/deployments/$deployment/chat/completions?api-version=$apiVersion';

    final body = <String, dynamic>{
      ...request.toJson(),
      'model': providerModel,
      'stream': stream,
    };
    // 与 openai.ts 同款注入(Azure 不委托 buildRequest,故在此镜像)。
    if (stream) {
      final so = body['stream_options'];
      final includeUsage = so is Map ? so['include_usage'] : null;
      if (includeUsage == null) {
        body['stream_options'] = <String, dynamic>{
          if (so is Map) ...Map<String, dynamic>.from(so),
          'include_usage': true,
        };
      }
    }
    return AdapterRequest(
      url,
      {
        'Content-Type': 'application/json',
        'api-key': providerApiKey,
      },
      jsonEncode(body),
    );
  }

  @override
  StreamEvent? parseStreamLine(String line, String providerModel) =>
      const OpenAIAdapter().parseStreamLine(line, providerModel);

  /// 从 endpoint 的 ?api-version= 提取(上游 extractApiVersion,用 URL 解析)。
  static String? _extractApiVersion(String endpoint) {
    final u = Uri.tryParse(endpoint);
    return u?.queryParameters['api-version'];
  }
}
