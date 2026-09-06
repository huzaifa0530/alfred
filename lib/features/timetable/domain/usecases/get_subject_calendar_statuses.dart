import '../../../attendance/domain/entities/attendance_record.dart';
import '../entities/day_attendance_status.dart';
import '../../../timetable/domain/entities/class_schedule.dart'; // adjust path

class GetSubjectCalendarStatuses {
  Map<DateTime, DayAttendanceStatus> call({
    required List<ClassSchedule> schedulesForSubject,
    required List<AttendanceRecord> recordsForSubject,
    required DateTime month, // any date inside the target month
    required DateTime today,
  }) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final todayNormalized = DateTime(today.year, today.month, today.day);

    final activeWeekdays = schedulesForSubject
        .where((s) => s.isActive)
        .map((s) => s.weekday)
        .toSet();

    final recordsByDate = <DateTime, AttendanceRecord>{
      for (final r in recordsForSubject)
        DateTime(r.date.year, r.date.month, r.date.day): r,
    };

    final result = <DateTime, DayAttendanceStatus>{};

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(firstDay.year, firstDay.month, day);

      if (!activeWeekdays.contains(date.weekday)) {
        result[date] = DayAttendanceStatus.noClass;
        continue;
      }

      final record = recordsByDate[date];
      if (record != null) {
        result[date] = record.present
            ? DayAttendanceStatus.present
            : DayAttendanceStatus.absent;
        continue;
      }

      result[date] = date.isAfter(todayNormalized)
          ? DayAttendanceStatus.future
          : DayAttendanceStatus.unmarked;
    }

    return result;
  }
}