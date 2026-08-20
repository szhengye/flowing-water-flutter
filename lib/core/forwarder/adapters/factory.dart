import 'anthropic.dart';
import 'azure_openai.dart';
import 'deepseek.dart';
import 'gemini.dart';
import 'openai.dart';
import 'types.dart';

/// 适配器工厂(对齐上游 `getAdapter`:逐调用新建实例)。
///
/// **5 adapter 全就绪**:OpenAI / DeepSeek / Azure(OpenAI 系,const)+
/// Anthropic(**非 const**:per-stream `openToolUses` 状态,每次新建隔离并发流)+
/// Gemini(const)。
ProviderAdapter makeAdapter(AdapterType t) => switch (t) {
      AdapterType.openai => const OpenAIAdapter(),
      AdapterType.deepseek => const DeepSeekAdapter(),
      AdapterType.azureOpenai => const AzureOpenAIAdapter(),
      AdapterType.anthropic => AnthropicAdapter(),
      AdapterType.gemini => const GeminiAdapter(),
    };
