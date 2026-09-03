import '../entities/attendance_record.dart';
import '../../../timetable/domain/entities/class_schedule.dart';

class SubjectAttendanceSummary {
  final int present;
  final int absent;
  final int expected;
  final double? percentage;

  SubjectAttendanceSummary({
    required this.present,
    required this.absent,
    required this.expected,
  }) : percentage = expected == 0 ? null : (present / expected) * 100;
}

class GetAttendanceSummary {
  SubjectAttendanceSummary call({
    required List<ClassSchedule> schedulesForSubject,
    required List<AttendanceRecord> recordsForSubject,
    required DateTime asOf,
  }) {
    final present = recordsForSubject.where((r) => r.present).length;
    final absent = recordsForSubject.where((r) => !r.present).length;

    var expected = 0;
    for (final schedule in schedulesForSubject) {
      expected += _occurrences(schedule.weekday, schedule.createdAt, asOf);
    }

    return SubjectAttendanceSummary(present: present, absent: absent, expected: expected);
  }

  int _occurrences(int weekday, DateTime from, DateTime to) {
    var cursor = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    if (end.isBefore(cursor)) return 0;

    final lead = (weekday - cursor.weekday) % 7;
    cursor = cursor.add(Duration(days: lead < 0 ? lead + 7 : lead));

    var count = 0;
    while (!cursor.isAfter(end)) {
      count++;
      cursor = cursor.add(const Duration(days: 7));
    }
    return count;
  }
}