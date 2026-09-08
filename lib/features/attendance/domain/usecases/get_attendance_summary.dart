import '../entities/attendance_record.dart';
import '../../../timetable/domain/entities/class_schedule.dart';

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
  }) : percentage = expected == 0 ? null : (present / expected) * 100;
}

class GetAttendanceSummary {
  SubjectAttendanceSummary call({
    required List<ClassSchedule> schedulesForSubject,
    required List<AttendanceRecord> recordsForSubject,
    required DateTime asOf,
  }) {
    // Only present + absent counts
    final present = recordsForSubject.where((r) => r.status == AttendanceStatus.present).length;
    final absent = recordsForSubject.where((r) => r.status == AttendanceStatus.absent).length;
    final cancelled = recordsForSubject.where((r) => r.status == AttendanceStatus.cancelled || r.status == AttendanceStatus.noClass).length;

    // expected = occurrences - cancelled occurrences
    // Simplest: expected = present + absent (actual taken classes)
    // If you want timetable based:
    var expectedFromTimetable = 0;
    for (final schedule in schedulesForSubject) {
      expectedFromTimetable += _occurrences(schedule.weekday, schedule.createdAt, asOf);
    }
    expectedFromTimetable -= cancelled; // <--- key line

    return SubjectAttendanceSummary(
      present: present, 
      absent: absent, 
      cancelled: cancelled,
      expected: present + absent, // use this for % so deleted timetable doesn't break
    );
  }

  int _occurrences(int weekday, DateTime from, DateTime to) { /* same as yours */ 
    var cursor = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    if (end.isBefore(cursor)) return 0;
    final lead = (weekday - cursor.weekday) % 7;
    cursor = cursor.add(Duration(days: lead < 0 ? lead + 7 : lead));
    var count = 0;
    while (!cursor.isAfter(end)) { count++; cursor = cursor.add(const Duration(days: 7)); }
    return count;
  }
}