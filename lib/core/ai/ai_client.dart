import 'package:alfred/core/ai/ai_provider.dart';

import 'ai_providers.dart';
import 'ai_settings_datasource.dart';
import 'gemini_client.dart';
import 'groq_client.dart';

class AiClient {
  final AiSettingsDataSource _settings;

  AiClient(this._settings);

  Future<String> generateText(String prompt) async {
    print('AI: generateText started');

    final provider = await _settings.getProvider();
    print('AI: provider = $provider');

    final apiKey = await _settings.getApiKey(provider);
    print('AI: API key exists = ${apiKey != null && apiKey.isNotEmpty}');

    final model = await _settings.getModel() ?? provider.defaultModel;
    print('AI: model = $model');

    if (apiKey == null || apiKey.trim().isEmpty) {
      throw StateError(
        'No ${provider.displayName} API key set. Add one in Settings → AI Provider.',
      );
    }

    print('AI: sending request...');

    switch (provider) {
      case AiProvider.gemini:
        final result = await GeminiClient(
          apiKey: apiKey,
          model: model,
        ).generateText(prompt);

        print('AI: Gemini response received');
        return result;

      case AiProvider.groq:
        final result = await GroqClient(
          apiKey: apiKey,
          model: model,
        ).generateText(prompt);

        print('AI: Groq response received');
        return result;
    }
  }
}
