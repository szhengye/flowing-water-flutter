import '../../relay/messages.dart';
import 'openai.dart';
import 'types.dart';

/// DeepSeek 适配器 —— 兼容 OpenAI 协议,纯委托 [OpenAIAdapter](仅 endpoint 不同,由
/// vendor 配置承载)。逐行移植 web3-api deepseek.ts(bind 三方法到 OpenAI 实例)。
class DeepSeekAdapter implements ProviderAdapter {
  const DeepSeekAdapter();

  static const _inner = OpenAIAdapter();

  @override
  AdapterType get type => AdapterType.deepseek;

  @override
  AdapterRequest buildRequest({
    required String providerEndpoint,
    required String providerApiKey,
    required String providerModel,
    required LlmRequest request,
    required bool stream,
  }) =>
      _inner.buildRequest(
        providerEndpoint: providerEndpoint,
        providerApiKey: providerApiKey,
        providerModel: providerModel,
        request: request,
        stream: stream,
      );

  @override
  StreamEvent? parseStreamLine(String line, String providerModel) =>
      _inner.parseStreamLine(line, providerModel);
}
