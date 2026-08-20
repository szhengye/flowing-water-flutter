import '../../relay/messages.dart';

/// Forwarder 适配层 —— wayfinder ticket 02 / 姊妹 spike 09 架构。
///
/// 镜像上游 `web3-api/.../forwarder/adapters/types.ts` 的接口形状:把中转站统一
/// [LlmRequest] 翻成某上游厂商原生 HTTP,再把流式响应翻回统一 chunk。逐调用新建
/// 适配器实例(Anthropic 带 per-stream `openToolUses` 状态,共享实例会让并发流的
/// tool_use 块索引串台 —— 见上游 adapters/index.ts 的工厂注释)。本会话落地 OpenAI;
/// Anthropic/Gemini/DeepSeek/Azure 留后续会话。

/// 与 provider_info.adapter_type / provider_llm_vendor.adapter_type 对齐(06 schema)。
enum AdapterType { openai, anthropic, gemini, deepseek, azureOpenai }

/// 适配器构造出的上游 HTTP 请求(对应上游 AdapterRequest)。
class AdapterRequest {
  const AdapterRequest(this.url, this.headers, this.body);
  final String url;
  final Map<String, String> headers;
  final String body; // JSON 串,UTF-8
}

/// 上游 SSE 逐行解析的统一产物(对应上游 AdapterStreamEvent)。
///
/// 单类多可选字段(非 sealed 多子类):一行 SSE 可同时携带 chunk 与 usage
/// (OpenAI 末尾的 usage chunk),sealed 单事件无法表达,故对齐 TS 形状。
/// 四字段全 null/false 即「无事件」(parseStreamLine 返回 null)。
class StreamEvent {
  const StreamEvent({this.chunk, this.usage, this.done = false, this.error});
  final LlmStreamChunk? chunk;
  final LlmUsage? usage;
  final bool done;
  final String? error;
}

/// 厂商适配器抽象。本会话只走流式(buildRequest + parseStreamLine);
/// 非流式 parseResponse 对齐上游时再补(YAGNI —— 当前无调用方)。
abstract class ProviderAdapter {
  AdapterType get type;

  /// 把统一 [request] 翻成厂商原生 HTTP 请求。[providerModel] 是 relayModel 经
  /// mapping 解析后的厂商真实模型名(覆盖 request.model)。
  AdapterRequest buildRequest({
    required String providerEndpoint,
    required String providerApiKey,
    required String providerModel,
    required LlmRequest request,
    required bool stream,
  });

  /// 解析一行上游流式输出(已去换行)。返回 null 表示该行无事件(如注释/心跳行)。
  StreamEvent? parseStreamLine(String line, String providerModel);
}
