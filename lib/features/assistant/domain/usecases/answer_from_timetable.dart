import 'package:alfred/core/ai/ai_client.dart';

import '../../../../core/ai/gemini_client.dart';
import '../../../timetable/domain/entities/class_schedule.dart';

class AnswerFromTimetable {
  final AiClient _client;

  AnswerFromTimetable(this._client);

  Future<String> call({
    required String question,
    required String subjectName,
    required List<ClassSchedule> schedules,
  }) async {
    if (schedules.isEmpty) {
      return "There's no class schedule recorded for $subjectName.";
    }

    final lines = schedules.where((s) => s.isActive).map((s) {
      final room = s.room == null ? '' : ', room ${s.room}';
      final teacher = s.teacher == null ? '' : ', with ${s.teacher}';
      return '- ${s.weekdayName}: ${s.startTime}–${s.endTime}$room$teacher';
    }).join('\n');

    final prompt =
        '''
Answer Sir Wayne's question using ONLY the class schedule below for
"$subjectName". Keep the answer short and direct.

SCHEDULE:
$lines

QUESTION:
$question
''';

    return _client.generateText(prompt);
  }
}