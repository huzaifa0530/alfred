import '../../../attendance/domain/entities/attendance_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../timetable/domain/entities/class_schedule.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/attendance_providers.dart';

Future<void> showMarkAttendanceSheet({
  required BuildContext context,
  required ClassSchedule schedule,
  required String subjectName,
  DateTime? initialDate, // optional - from TimetableScreen
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => MarkAttendanceSheet(
      schedule: schedule,
      subjectName: subjectName,
      initialDate: initialDate,
    ),
  );
}

class MarkAttendanceSheet extends ConsumerStatefulWidget {
  final ClassSchedule schedule;
  final String subjectName;
  final DateTime? initialDate;
  const MarkAttendanceSheet({
    super.key,
    required this.schedule,
    required this.subjectName,
    this.initialDate,
  });

  @override
  ConsumerState<MarkAttendanceSheet> createState() => _MarkAttendanceSheetState();
}

class _MarkAttendanceSheetState extends ConsumerState<MarkAttendanceSheet> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    // Use passed date (from DaySelector) or this week's weekday date
    _selectedDate = widget.initialDate ?? dateForWeekday(widget.schedule.weekday);
    // strip time
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
  }

  bool _isSelectable(DateTime day) {
    // only same weekday as class + not in future
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dayOnly = DateTime(day.year, day.month, day.day);
    return day.weekday == widget.schedule.weekday && !dayOnly.isAfter(todayOnly);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final isFuture = _selectedDate.isAfter(todayOnly);

    final key = (scheduleId: widget.schedule.id, date: _selectedDate);
    final existingAsync = ref.watch(attendanceForScheduleProvider(key));

    Future<void> mark(AttendanceStatus status) async {
      await ref.read(attendanceControllerProvider).markAttendance(
            subjectId: widget.schedule.subjectId,
            scheduleId: widget.schedule.id,
            date: _selectedDate, // <-- now uses picked prev date
            status: status,
          );
      if (context.mounted) Navigator.of(context).pop();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subjectName,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${widget.schedule.startTime} - ${widget.schedule.endTime}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),

            // DATE PICKER CHIP
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                  selectableDayPredicate: _isSelectable, // only same weekday
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = DateTime(picked.year, picked.month, picked.day);
                  });
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} • ${_weekdayName(_selectedDate.weekday)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_rounded, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (isFuture) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon(Icons.schedule_rounded,
                      color: theme.colorScheme.onSurfaceVariant, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text("Can't mark future class.",
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                ]),
              ),
              const SizedBox(height: 16),
            ] else
              existingAsync.when(
                loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox.shrink(),
                data: (record) {
                  if (record == null) return const SizedBox.shrink();
                  final label = switch (record.status) {
                    AttendanceStatus.present => 'Currently: Present on ${_selectedDate.day}/${_selectedDate.month}',
                    AttendanceStatus.absent => 'Currently: Absent on ${_selectedDate.day}/${_selectedDate.month}',
                    AttendanceStatus.cancelled => 'Currently: Cancelled',
                    AttendanceStatus.noClass => 'Currently: No Class',
                  };
                  return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(label,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700)));
                },
              ),

            Row(children: [
              Expanded(
                  child: FilledButton.icon(
                      onPressed: isFuture ? null : () => mark(AttendanceStatus.present),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Present'))),
              const SizedBox(width: 12),
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: isFuture ? null : () => mark(AttendanceStatus.absent),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Absent'))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: isFuture ? null : () => mark(AttendanceStatus.cancelled),
                      icon: const Icon(Icons.block_rounded),
                      label: const Text('Cancelled'))),
              const SizedBox(width: 12),
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: isFuture ? null : () => mark(AttendanceStatus.noClass),
                      icon: const Icon(Icons.event_busy_rounded),
                      label: const Text('No Class'))),
            ]),
          ],
        ),
      ),
    );
  }

  String _weekdayName(int day) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];
}