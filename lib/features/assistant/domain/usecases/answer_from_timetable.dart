import 'package:alfred/core/ai/ai_client.dart';

import '../../../timetable/domain/entities/class_schedule.dart';

class AnswerFromTimetable {
  final AiClient _client;

  AnswerFromTimetable(this._client);

  Future<String> call({
    required String question,
    required String subjectName,
    required List<ClassSchedule> schedules,
    Map<int, String>? subjectNamesById, // subjectId -> name, for multi-subject answers
  }) async {
    if (schedules.isEmpty) {
      return "There's no class schedule recorded for $subjectName.";
    }

    final lines = schedules.where((s) => s.isActive).map((s) {
      final room = s.room == null ? '' : ', room ${s.room}';
      final teacher = s.teacher == null ? '' : ', with ${s.teacher}';
      final subjectLabel = subjectNamesById?[s.subjectId] ?? subjectName;
      return '- $subjectLabel — ${s.weekdayName}: ${s.startTime}–${s.endTime}$room$teacher';
    }).join('\n');

    final prompt =
        '''
Answer Sir Wayne's question using ONLY the class schedule below. Each line
names the subject that class belongs to — always mention the subject name
in your answer, never just the time and room. Keep the answer short and direct.

SCHEDULE:
$lines

QUESTION:
$question
''';

    return _client.generateText(prompt);
  }
}