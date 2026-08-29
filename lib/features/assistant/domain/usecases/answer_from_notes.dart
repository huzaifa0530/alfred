import 'package:alfred/core/ai/ai_client.dart';
import 'package:alfred/core/ai/alfred_persona.dart';

import '../../../notes/domain/entities/note.dart';

class AnswerFromNotes {
  final AiClient _client;

  AnswerFromNotes(this._client);

  Future<String> call({
    required String question,
    required String subjectName,
    required List<Note> notes,
  }) async {
    if (notes.isEmpty) {
      return "There aren't any notes in $subjectName yet.";
    }

    final combined = notes
        .map((n) => '- ${n.content}')
        .where((line) => line.trim() != '-')
        .join('\n');



    final prompt =
        '''
${AlfredPersona.preamble}

Answer Master Wayne's question using ONLY the notes below from his
"$subjectName" subject. If the notes don't contain the answer, say so plainly
instead of guessing. Keep the answer short and direct.

NOTES:
$combined

QUESTION:
$question
''';

    return _client.generateText(prompt);
  }
}