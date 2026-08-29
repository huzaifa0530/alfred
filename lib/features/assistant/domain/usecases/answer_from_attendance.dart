import '../../../../core/ai/gemini_client.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import 'package:alfred/core/ai/ai_client.dart';

class AnswerFromAttendance {
  final AiClient _client;

  AnswerFromAttendance(this._client);

  Future<String> call({
    required String question,
    required String subjectName,
    required List<AttendanceRecord> records,
  }) async {
    if (records.isEmpty) {
      return "There is no attendance recorded for $subjectName yet.";
    }

    final presentCount = records.where((r) => r.present).length;
    final total = records.length;
    final percentage = total == 0 ? 0.0 : (presentCount / total) * 100;

    final lines = records.map((r) {
      final status = r.present ? 'present' : 'absent';
      final note = r.note == null ? '' : ' (${r.note})';
      return '- ${r.date}: $status$note';
    }).join('\n');

    final prompt =
        '''
Answer Sir Wayne's question using the attendance data below for
"$subjectName". Overall attendance is $presentCount/$total (${percentage.toStringAsFixed(1)}%).
Do any extra math yourself if asked (e.g. "how many can I miss to stay above 75%").
Keep the answer short and direct.

RECORDS:
$lines

QUESTION:
$question
''';

    return _client.generateText(prompt);
  }
}