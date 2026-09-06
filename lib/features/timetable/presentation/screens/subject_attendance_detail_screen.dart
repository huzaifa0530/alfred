import 'package:alfred/features/attendance/presentation/controllers/attendance_controller.dart';
import 'package:alfred/features/attendance/presentation/controllers/attendance_providers.dart';
import 'package:alfred/features/timetable/presentation/controllers/timetable_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../subjects/domain/entities/subject.dart';
import '../widgets/attendance_calendar.dart';

class SubjectAttendanceDetailScreen extends ConsumerStatefulWidget {
  final Subject subject;
  const SubjectAttendanceDetailScreen({super.key, required this.subject});

  @override
  ConsumerState<SubjectAttendanceDetailScreen> createState() =>
      _SubjectAttendanceDetailScreenState();
}

class _SubjectAttendanceDetailScreenState
    extends ConsumerState<SubjectAttendanceDetailScreen> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;
    final attendanceAsync = ref.watch(attendanceForSubjectProvider(subject.id));
    final schedules = ref.watch(schedulesForSubjectProvider(subject.id));

    return Scaffold(
      appBar: AppBar(title: Text(subject.name)),
      body: attendanceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Unable to load attendance')),
        data: (records) {
          final summary = ref.read(getAttendanceSummaryProvider).call(
                schedulesForSubject: schedules,
                recordsForSubject: records,
                asOf: DateTime.now(),
              );

          final statuses = ref.read(getSubjectCalendarStatusesProvider).call(
                schedulesForSubject: schedules,
                recordsForSubject: records,
                month: _visibleMonth,
                today: DateTime.now(),
              );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              _SummaryHeader(percentage: summary.percentage, present: summary.present, absent: summary.absent),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: AttendanceCalendar(
                  month: _visibleMonth,
                  statuses: statuses,
                  onPreviousMonth: () => setState(() =>
                      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1)),
                  onNextMonth: () => setState(() =>
                      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1)),
                  onDayTap: (date) => _showMarkSheet(date, schedules),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showMarkSheet(DateTime date, List schedules) async {
    final matching = schedules.where((s) => s.weekday == date.weekday && s.isActive).toList();
    if (matching.isEmpty) return;

    // If a subject has 2+ slots on the same weekday, this marks against the
    // first one — split into per-slot marking if you need that distinction.
    final scheduleId = matching.first.id;

    final choice = await showModalBottomSheet<bool?>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.check_circle_outline, color: Colors.green),
            title: const Text('Mark present'),
            onTap: () => Navigator.pop(context, true),
          ),
          ListTile(
            leading: const Icon(Icons.cancel_outlined, color: Colors.red),
            title: const Text('Mark absent'),
            onTap: () => Navigator.pop(context, false),
          ),
        ]),
      ),
    );

    if (choice == null) return;

    await ref.read(attendanceControllerProvider).markAttendance(
          subjectId: widget.subject.id,
          scheduleId: scheduleId,
          date: date,
          present: choice,
        );
  }
}

class _SummaryHeader extends StatelessWidget {
  final double? percentage;
  final int present;
  final int absent;
  const _SummaryHeader({required this.percentage, required this.present, required this.absent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = percentage == null ? '—' : '${percentage!.toStringAsFixed(0)}%';
    return Row(
      children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
          child: Center(child: Text(text, style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800, color: theme.colorScheme.onPrimaryContainer))),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$present classes present', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('$absent classes absent', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ],
    );
  }
}