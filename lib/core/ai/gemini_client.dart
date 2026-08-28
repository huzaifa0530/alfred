import 'package:google_generative_ai/google_generative_ai.dart';

import 'ai_config.dart';

class GeminiClient {
  GeminiClient()
      : _model = GenerativeModel(
          model: AiConfig.modelName,
          apiKey: AiConfig.apiKey,
        );

  final GenerativeModel _model;

  Future<String> generateText(String prompt) async {
    if (AiConfig.apiKey.isEmpty || AiConfig.apiKey.startsWith('PASTE_')) {
      throw StateError(
        'Gemini API key is not set. Add it in core/ai/ai_config.dart.',
      );
    }

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text;

    if (text == null || text.trim().isEmpty) {
      throw StateError('Gemini returned an empty response.');
    }

    return text.trim();
  }
}