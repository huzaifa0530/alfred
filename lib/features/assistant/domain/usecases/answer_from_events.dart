import '../../../../core/ai/gemini_client.dart';
import '../../../events/domain/entities/event.dart';
import 'package:alfred/core/ai/ai_client.dart';

class AnswerFromEvents {
  final AiClient _client;

  AnswerFromEvents(this._client);

  Future<String> call({
    required String question,
    required String subjectName,
    required List<Event> events,
  }) async {
    if (events.isEmpty) {
      return "There are no events/deadlines recorded for $subjectName.";
    }

    final lines = events.map((e) {
      final status = e.isCompleted
          ? 'completed'
          : e.isOverdue
              ? 'OVERDUE'
              : 'upcoming';
      final desc = e.description == null ? '' : ' — ${e.description}';
      return '- ${e.title} [${e.type}, ${e.priority} priority, due ${e.dueDate}, $status]$desc';
    }).join('\n');

    final prompt =
        '''
Answer Sir Wayne's question using ONLY the events/deadlines below for
"$subjectName". Keep the answer short and direct.

EVENTS:
$lines

QUESTION:
$question
''';

    return _client.generateText(prompt);
  }
}