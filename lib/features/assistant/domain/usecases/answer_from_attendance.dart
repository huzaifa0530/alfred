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

    final sorted = [...records]..sort((a,b) => a.date.compareTo(b.date));

    final presentCount = sorted.where((r) => r.status == AttendanceStatus.present).length;
    final absentCount = sorted.where((r) => r.status == AttendanceStatus.absent).length;
    final cancelledCount = sorted.where((r) => r.status == AttendanceStatus.cancelled || r.status == AttendanceStatus.noClass).length;
    final totalForPercent = presentCount + absentCount;
    final percentage = totalForPercent == 0 ? 0.0 : (presentCount / totalForPercent) * 100;

    final lines = sorted.map((r) =>
      '- ${r.date.toIso8601String().split('T').first}: ${r.status.name}${r.note == null ? '' : ' (${r.note})'}'
    ).join('\n');

    final prompt = '''
Answer Sir Wayne's question using attendance for "$subjectName".
Stats: $presentCount present, $absentCount absent, $cancelledCount cancelled/noClass (excluded from calculation).
Overall attendance = $presentCount / $totalForPercent = ${percentage.toStringAsFixed(1)}% (present+absent only, cancelled has 0 effect).
If asked "how many can I miss", calculate using present+absent only.

RECORDS:
$lines

QUESTION:
$question
''';
    return _client.generateText(prompt);
  }
}