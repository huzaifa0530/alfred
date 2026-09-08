import '../../../attendance/domain/entities/attendance_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../timetable/domain/entities/class_schedule.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/attendance_providers.dart';

Future<void> showMarkAttendanceSheet({required BuildContext context, required ClassSchedule schedule, required String subjectName}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => MarkAttendanceSheet(schedule: schedule, subjectName: subjectName),
  );
}

class MarkAttendanceSheet extends ConsumerWidget {
  final ClassSchedule schedule;
  final String subjectName;
  const MarkAttendanceSheet({super.key, required this.schedule, required this.subjectName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final date = dateForWeekday(schedule.weekday);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final isFuture = dateOnly.isAfter(todayOnly);
    final key = (scheduleId: schedule.id, date: date);
    final existingAsync = ref.watch(attendanceForScheduleProvider(key));

    Future<void> mark(AttendanceStatus status) async {
      await ref.read(attendanceControllerProvider).markAttendance(
            subjectId: schedule.subjectId,
            scheduleId: schedule.id,
            date: date,
            status: status, // <-- changed from bool to status
          );
      if (context.mounted) Navigator.of(context).pop();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(subjectName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${schedule.startTime} - ${schedule.endTime}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          if (isFuture) ...[
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(Icons.schedule_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text("This class hasn't happened yet — you can mark attendance once it starts.", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
              ]),
            ),
            const SizedBox(height: 16),
          ] else
            existingAsync.when(
              loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
              data: (record) {
                if (record == null) return const SizedBox.shrink();
                final label = switch (record.status) {
                  AttendanceStatus.present => 'Currently marked: Present',
                  AttendanceStatus.absent => 'Currently marked: Absent',
                  AttendanceStatus.cancelled => 'Currently marked: Cancelled - no effect on %',
                  AttendanceStatus.noClass => 'Currently marked: No Class - no effect on %',
                };
                return Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)));
              },
            ),
          Row(children: [
            Expanded(child: FilledButton.icon(onPressed: isFuture ? null : () => mark(AttendanceStatus.present), icon: const Icon(Icons.check_rounded), label: const Text('Present'))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(onPressed: isFuture ? null : () => mark(AttendanceStatus.absent), icon: const Icon(Icons.close_rounded), label: const Text('Absent'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: isFuture ? null : () => mark(AttendanceStatus.cancelled), icon: const Icon(Icons.block_rounded), label: const Text('Cancelled'))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(onPressed: isFuture ? null : () => mark(AttendanceStatus.noClass), icon: const Icon(Icons.event_busy_rounded), label: const Text('No Class'))),
          ]),
        ]),
      ),
    );
  }
}