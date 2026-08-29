enum AiProvider { gemini, groq }

class AiModelOption {
  final String id;
  final String label;
  const AiModelOption(this.id, this.label);
}

extension AiProviderX on AiProvider {
  String get displayName => switch (this) {
    AiProvider.gemini => 'Gemini',
    AiProvider.groq => 'Groq',
  };

  List<AiModelOption> get availableModels => switch (this) {
    AiProvider.gemini => const [
      AiModelOption('gemini-3.6-flash', 'Gemini 3.6 Flash'),
      AiModelOption('gemini-3.5-flash', 'Gemini 3.5 Flash'),
    ],
    AiProvider.groq => const [
      AiModelOption('openai/gpt-oss-120b', 'GPT-OSS 120B'),
      AiModelOption('openai/gpt-oss-20b', 'GPT-OSS 20B'),
      AiModelOption('qwen/qwen3.6-27b', 'Qwen 3.6 27B'),
    ],
  };

  String get defaultModel => availableModels.first.id;

  String get apiKeyHelpUrl => switch (this) {
    AiProvider.gemini => 'https://aistudio.google.com/apikey',
    AiProvider.groq => 'https://console.groq.com/keys',
  };
}
