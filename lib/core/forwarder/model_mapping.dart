import '../db/database.dart';
import 'adapters/types.dart';

/// relayModel → 厂商连接配置 + providerModel + 时点报价。
///
/// dispatcher 据 `request.model`(relayModel)解析出上游 vendor(endpoint/key/adapter)、
/// 真实 providerModel(覆盖)、以及计费用的时点价。来源两张表:provider_quotation
/// (relayModel→providerModel/providerId/报价) + provider_llm_vendor(providerId→
/// endpoint/key/adapterType/supportsStream)。
class ProviderMapping {
  const ProviderMapping({
    required this.endpoint,
    required this.apiKey,
    required this.adapterType,
    required this.supportsStream,
    required this.providerModel,
    required this.inputPricePer1k,
    required this.outputPricePer1k,
  });

  final String endpoint;
  final String apiKey;
  final AdapterType adapterType;
  final bool supportsStream;
  final String providerModel;
  final int inputPricePer1k; // nUSD / 1K tokens(时点价快照)
  final int outputPricePer1k;
}

/// 解析 relayModel → [ProviderMapping]。无 quotation / 无 vendor → null
/// (调用方据此 onError("No model mapping"),与上游 forwardStreamRequest 同语义)。
Future<ProviderMapping?> resolveProviderMapping(
  AppDatabase db,
  String relayModel,
) async {
  final q = await (db.select(db.providerQuotations)
        ..where((t) => t.relayModelName.equals(relayModel)))
      .getSingleOrNull();
  if (q == null || q.providerId == null) return null;
  final v = await (db.select(db.providerLlmVendors)
        ..where((t) => t.vendorId.equals(q.providerId!)))
      .getSingleOrNull();
  if (v == null) return null;
  return ProviderMapping(
    endpoint: v.endpoint,
    apiKey: v.apiKey,
    adapterType: parseAdapterType(v.adapterType),
    supportsStream: v.supportsStream,
    providerModel: q.providerModel ?? relayModel,
    inputPricePer1k: q.inputPricePer1k,
    outputPricePer1k: q.outputPricePer1k,
  );
}

/// vendor.adapterType(text)→enum。未知默认 openai(上游 getAdapter 同样默认)。
AdapterType parseAdapterType(String s) => switch (s) {
      'openai' => AdapterType.openai,
      'anthropic' => AdapterType.anthropic,
      'gemini' => AdapterType.gemini,
      'deepseek' => AdapterType.deepseek,
      'azure_openai' => AdapterType.azureOpenai,
      _ => AdapterType.openai,
    };
