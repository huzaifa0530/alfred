import '../../../timetable/domain/entities/class_schedule.dart';
import '../entities/attendance_record.dart';

class SubjectAttendanceSummary {
  final int present;
  final int absent;
  final int cancelled;
  final int expected;
  final double? percentage;

  SubjectAttendanceSummary({
    required this.present,
    required this.absent,
    required this.cancelled,
    required this.expected,
  }) : percentage = expected == 0? null : (present / expected) * 100;
}

class GetAttendanceSummary {
  SubjectAttendanceSummary call({
    required List<ClassSchedule> schedulesForSubject,
    required List<AttendanceRecord> recordsForSubject,
    required DateTime asOf,
  }) {
    final present = recordsForSubject.where((r) => r.status == AttendanceStatus.present).length;
    final absent = recordsForSubject.where((r) => r.status == AttendanceStatus.absent).length;
    final cancelled = recordsForSubject.where((r) => r.status == AttendanceStatus.cancelled || r.status == AttendanceStatus.noClass).length;

    // % should be present / (present + absent) only - cancelled/noClass has 0 effect
    final expected = present + absent;

    return SubjectAttendanceSummary(
      present: present,
      absent: absent,
      cancelled: cancelled,
      expected: expected,
    );
  }
}