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
    required bool present,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    final record = AttendanceRecord(
      id: 0,
      subjectId: subjectId,
      scheduleId: scheduleId,
      date: normalizedDate,
      present: present,
      markedAt: DateTime.now(),
    );

    await ref.read(createAttendanceProvider)(record);

    ref.invalidate(
      // ✅ CORRECT
      attendanceForScheduleProvider((
        scheduleId: scheduleId,
        date: normalizedDate,
      )),
    );
  }
}

final attendanceControllerProvider = Provider<AttendanceController>((ref) {
  return AttendanceController(ref);
});
