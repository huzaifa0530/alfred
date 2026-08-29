import '../../../../core/ai/gemini_client.dart';
import '../../../marks/domain/entities/mark.dart';
import '../../../marks/domain/entities/mark_component.dart';
import 'package:alfred/core/ai/ai_client.dart';

class AnswerFromMarks {
  final AiClient _client;

  AnswerFromMarks(this._client);

  Future<String> call({
    required String question,
    required String subjectName,
    required List<MarkComponent> components,
    required List<Mark> marks,
  }) async {
    if (components.isEmpty) {
      return "There aren't any assessments recorded for $subjectName yet.";
    }

    final markMap = {for (final m in marks) m.componentId: m};

    final lines = components.map((c) {
      final obtained = markMap[c.id]?.obtainedMarks;
      final gotText = obtained == null ? 'not entered' : obtained.toString();
      return '- ${c.name} (${c.type ?? 'other'}): $gotText / ${c.maxMarks}';
    }).join('\n');

    final prompt =
        '''
Answer Sir Wayne's question using ONLY the marks data below for"
$subjectName". Do simple math (totals, percentages) yourself if asked.
Keep the answer short and direct.

MARKS:
$lines

QUESTION:
$question
''';

    return _client.generateText(prompt);
  }
}