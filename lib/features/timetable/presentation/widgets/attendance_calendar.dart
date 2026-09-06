import 'package:flutter/material.dart';
import '../../domain/entities/day_attendance_status.dart';

class AttendanceCalendar extends StatelessWidget {
  final DateTime month;
  final Map<DateTime, DayAttendanceStatus> statuses;
  final ValueChanged<DateTime> onDayTap;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const AttendanceCalendar({
    super.key,
    required this.month,
    required this.statuses,
    required this.onDayTap,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1; // Monday = 1

    final cells = <Widget>[
      for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          date: DateTime(month.year, month.month, day),
          status: statuses[DateTime(month.year, month.month, day)] ??
              DayAttendanceStatus.noClass,
          onTap: () => onDayTap(DateTime(month.year, month.month, day)),
        ),
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(onPressed: onPreviousMonth, icon: const Icon(Icons.chevron_left_rounded)),
            Text('${_monthNames[month.month - 1]} ${month.year}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            IconButton(onPressed: onNextMonth, icon: const Icon(Icons.chevron_right_rounded)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: _weekdayLabels
              .map((l) => Expanded(
                    child: Center(
                      child: Text(l,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: cells,
        ),
        const SizedBox(height: 14),
        const _CalendarLegend(),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final DayAttendanceStatus status;
  final VoidCallback onTap;

  const _DayCell({required this.date, required this.status, required this.onTap});

  bool _isToday(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color? background;
    Color textColor = theme.colorScheme.onSurface;
    Border? border;

    switch (status) {
      case DayAttendanceStatus.present:
        background = Colors.green.withValues(alpha: 0.85);
        textColor = Colors.white;
        break;
      case DayAttendanceStatus.absent:
        background = Colors.red.withValues(alpha: 0.85);
        textColor = Colors.white;
        break;
      case DayAttendanceStatus.unmarked:
        border = Border.all(color: Colors.amber, width: 1.4);
        break;
      case DayAttendanceStatus.future:
        textColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
        break;
      case DayAttendanceStatus.noClass:
        textColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35);
        break;
    }

    final canTap = status == DayAttendanceStatus.present ||
        status == DayAttendanceStatus.absent ||
        status == DayAttendanceStatus.unmarked;

    return InkWell(
      onTap: canTap ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: border ??
              (_isToday(date, DateTime.now())
                  ? Border.all(color: theme.colorScheme.primary, width: 1.4)
                  : null),
        ),
        alignment: Alignment.center,
        child: Text('${date.day}',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        );

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        item(Colors.green, 'Present'),
        item(Colors.red, 'Absent'),
        item(Colors.amber, 'Needs marking'),
        item(theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35), 'No class'),
      ],
    );
  }
}