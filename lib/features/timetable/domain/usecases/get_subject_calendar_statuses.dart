import '../../../attendance/domain/entities/attendance_record.dart';
import '../entities/day_attendance_status.dart';
import '../../../timetable/domain/entities/class_schedule.dart';

class GetSubjectCalendarStatuses {
  Map<DateTime, DayAttendanceStatus> call({
    required List<ClassSchedule> schedulesForSubject,
    required List<AttendanceRecord> recordsForSubject,
    required DateTime month,
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
      final dateOnly = DateTime(date.year, date.month, date.day);

      // if you explicitly marked it - show exactly what you marked
      if (recordsByDate.containsKey(dateOnly)) {
        final record = recordsByDate[dateOnly]!;
        switch (record.status) {
          case AttendanceStatus.present:
            result[dateOnly] = DayAttendanceStatus.present;
            break;
          case AttendanceStatus.absent:
            result[dateOnly] = DayAttendanceStatus.absent;
            break;
          case AttendanceStatus.cancelled:
            result[dateOnly] = DayAttendanceStatus.cancelled; // orange, not red
            break;
          case AttendanceStatus.noClass:
            result[dateOnly] = DayAttendanceStatus.noClass; // grey, not red
            break;
        }
        continue;
      }

      // not marked
      if (!activeWeekdays.contains(date.weekday)) {
        result[dateOnly] = DayAttendanceStatus.noClass;
        continue;
      }

      result[dateOnly] = dateOnly.isAfter(todayNormalized)
         ? DayAttendanceStatus.future
          : DayAttendanceStatus.unmarked; // amber border, not red
    }

    return result;
  }
}