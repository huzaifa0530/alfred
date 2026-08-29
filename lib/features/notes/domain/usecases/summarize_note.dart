import 'package:alfred/core/ai/ai_client.dart';

import '../../../../core/ai/gemini_client.dart';

class SummarizeNote {
  final AiClient _client;

  SummarizeNote(this._client);

  Future<String> call(String noteContent) async {
    final cleaned = noteContent.trim();

    if (cleaned.isEmpty) {
      throw ArgumentError('Note is empty — nothing to summarize.');
    }

    final prompt =
        '''
You are helping a student clean up a quick note they typed on their phone.
Rewrite the note below so it is clear, well-structured, and concise.
Keep all facts, numbers, and names exactly as given. Do not add new information.
Return only the rewritten note, no preamble, no markdown headers.

NOTE:
"""
$cleaned
"""
''';

    return _client.generateText(prompt);
  }
}