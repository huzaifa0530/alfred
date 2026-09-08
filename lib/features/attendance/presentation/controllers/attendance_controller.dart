import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/attendance_record.dart';
import 'attendance_providers.dart';

class AttendanceController {
  final Ref ref;

  AttendanceController(this.ref);
Future<void> markAttendance({
  required int subjectId,
  required int scheduleId,
  required DateTime date,
  required AttendanceStatus status,
}) async {
  final normalizedDate = DateTime(date.year, date.month, date.day);
  final record = AttendanceRecord(
    id: 0, subjectId: subjectId, scheduleId: scheduleId,
    date: normalizedDate, status: status, markedAt: DateTime.now(),
  );
  await ref.read(createAttendanceProvider)(record);
  ref.invalidate(attendanceForScheduleProvider((scheduleId: scheduleId, date: normalizedDate)));
}}

final attendanceControllerProvider = Provider<AttendanceController>((ref) {
  return AttendanceController(ref);
});
