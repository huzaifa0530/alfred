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
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return MarkAttendanceSheet(schedule: schedule, subjectName: subjectName);
    },
  );
}

class MarkAttendanceSheet extends ConsumerWidget {
  final ClassSchedule schedule;
  final String subjectName;

  const MarkAttendanceSheet({
    super.key,
    required this.schedule,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final date = dateForWeekday(schedule.weekday);
    final key = (scheduleId: schedule.id, date: date);

    final existingAsync = ref.watch(attendanceForScheduleProvider(key));

    Future<void> mark(bool present) async {
      await ref.read(attendanceControllerProvider).markAttendance(
            subjectId: schedule.subjectId,
            scheduleId: schedule.id,
            date: date,
            present: present,
          );

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subjectName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${schedule.startTime} - ${schedule.endTime}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            existingAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (record) {
                if (record == null) return const SizedBox.shrink();

                final label = record.present
                    ? 'Currently marked: Present'
                    : 'Currently marked: Absent';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => mark(true),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Present'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => mark(false),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Absent'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}