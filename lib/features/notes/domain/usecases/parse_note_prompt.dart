import 'dart:convert';

import '../../../../core/ai/gemini_client.dart';
import 'package:alfred/core/ai/ai_client.dart';

class ParsedNotePrompt {
  final String? subjectName;
  final String content;
  final bool isNoteIntent;

  const ParsedNotePrompt({
    required this.subjectName,
    required this.content,
    required this.isNoteIntent,
  });
}

class ParseNotePrompt {
  final AiClient _client;

  ParseNotePrompt(this._client);

  Future<ParsedNotePrompt> call({
    required String prompt,
    required List<String> subjectNames,
  }) async {
    final cleanedPrompt = prompt.trim();

    if (cleanedPrompt.isEmpty) {
      throw ArgumentError('Prompt is empty.');
    }

    final subjectList = subjectNames.isEmpty ? 'none' : subjectNames.join(', ');

    final instruction =
        '''
You turn a short instruction into a note for a student app.
The student's existing subjects are: $subjectList

Decide:
- isNoteIntent: true if the student is asking to save/add/create a note, false otherwise.
- subjectName: the closest matching subject from the list above, or null if none fits.
- content: the actual information to remember, cleaned up — drop phrases like
  "add a note" or "remind me", keep facts/numbers/dates exactly as given.

Respond with ONLY raw JSON, no markdown, no code fences, in this exact shape:
{"isNoteIntent": true, "subjectName": "Physics", "content": "Quiz is on Friday covering chapters 3-4."}

INSTRUCTION:
"""
$cleanedPrompt
"""
''';

    final raw = await _client.generateText(instruction);
    final decoded = jsonDecode(_extractJson(raw)) as Map<String, dynamic>;

    final subjectName = (decoded['subjectName'] as String?)?.trim();

    return ParsedNotePrompt(
      isNoteIntent: decoded['isNoteIntent'] == true,
      subjectName: (subjectName == null || subjectName.isEmpty) ? null : subjectName,
      content: (decoded['content'] as String? ?? cleanedPrompt).trim(),
    );
  }

  String _extractJson(String raw) {
    var text = raw.trim().replaceAll('```json', '').replaceAll('```', '').trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');

    if (start == -1 || end == -1 || end < start) {
      throw StateError('Could not parse AI response as JSON: $raw');
    }

    return text.substring(start, end + 1);
  }
}