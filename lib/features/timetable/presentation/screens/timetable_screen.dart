import 'package:alfred/app/router/route_names.dart';
import 'package:alfred/features/attendance/presentation/controllers/attendance_providers.dart';
import 'package:alfred/features/subjects/presentation/controllers/subjects_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../attendance/presentation/widgets/mark_attendance_sheet.dart';
import '../../domain/entities/class_schedule.dart';
import '../controllers/timetable_providers.dart';
import '../widgets/class_card.dart';
import '../widgets/day_selector.dart';
import 'create_class_screen.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  DateTime _selectedDate = DateTime.now(); // NEW - holds real date
  int get _selectedDay => _selectedDate.weekday;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(), // no future
    );
    if (picked!= null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(timetableForDayProvider(_selectedDay));
    final subjectsAsync = ref.watch(subjectsControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      selectedDate: _selectedDate,
                      onTodayPressed: () {
                        setState(() => _selectedDate = DateTime.now());
                      },
                      onDatePressed: _pickDate, // NEW
                    ),
                    const SizedBox(height: 24),
                    DaySelector(
                      selectedDay: _selectedDay,
                      onDayChanged: (day) {
                        // when you tap Mon/Tue, keep same week but change day
                        final diff = day - _selectedDate.weekday;
                        setState(() {
                          _selectedDate = _selectedDate.add(Duration(days: diff));
                        });
                      },
                    ),
                    const SizedBox(height: 28),
                    _DayHeading(
                      date: _selectedDate, // pass real date
                      onTap: _pickDate, // tap to change date
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            schedulesAsync.when(
              loading: () => const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(hasScrollBody: false, child: _ErrorState(onRetry: () => ref.invalidate(timetableForDayProvider(_selectedDay)))),
              data: (schedules) {
                final subjects = subjectsAsync.maybeWhen(data: (items) => items, orElse: () => const []);
                String subjectName(int id) {
                  for (final s in subjects) if (s.id == id) return s.name;
                  return 'Unknown subject';
                }
                if (schedules.isEmpty) return const SliverFillRemaining(hasScrollBody: false, child: _EmptyState());

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList.separated(
                    itemCount: schedules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final schedule = schedules[index];
                      final name = subjectName(schedule.subjectId);

                      // USE _selectedDate DIRECTLY, NOT dateForWeekday
                      final dateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                      final attendanceKey = (scheduleId: schedule.id, date: dateOnly);
                      final attendanceAsync = ref.watch(attendanceForScheduleProvider(attendanceKey));
                      final record = attendanceAsync.maybeWhen(data: (r) => r, orElse: () => null);

                      return ClassCard(
                        schedule: schedule,
                        subjectName: name,
                        attendance: record,
                        onTap: () {
                          showMarkAttendanceSheet(
                            context: context,
                            schedule: schedule,
                            subjectName: name,
                            initialDate: dateOnly, // <-- REAL prev date
                          );
                        },
                        onEdit: () async => await _editSchedule(schedule),
                        onDelete: () async {
                          await ref.read(timetableRepositoryProvider).deleteSchedule(schedule.id);
                          if (!mounted) return;
                          ref.invalidate(timetableForDayProvider(_selectedDay));
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push<bool>('${RouteNames.timetable}/create');
          if (result == true) ref.invalidate(timetableForDayProvider(_selectedDay));
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add class'),
      ),
    );
  }

  Future<void> _editSchedule(ClassSchedule schedule) async {
    final result = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateClassScreen(schedule: schedule)));
    if (!mounted) return;
    if (result == true) ref.invalidate(timetableForDayProvider(_selectedDay));
  }
}
// ─────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onTodayPressed;
  final VoidCallback onDatePressed;
  final DateTime selectedDate;
  const _Header({required this.onTodayPressed, required this.onDatePressed, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Timetable', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.2)),
            const SizedBox(height: 6),
            Text('Your weekly rhythm.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
        // DATE PICKER BUTTON
        Material(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onDatePressed,
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('${selectedDate.day}/${selectedDate.month}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onTodayPressed,
            borderRadius: BorderRadius.circular(15),
            child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.today_outlined)),
          ),
        ),
      ],
    );
  }
}

class _DayHeading extends StatelessWidget {
  final DateTime date; // CHANGE from int weekday to DateTime
  final VoidCallback onTap; // tap to pick prev date

  const _DayHeading({
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isToday(date);
    final isPast = date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _weekdayName(date.weekday),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isPast ? theme.colorScheme.primary : null,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('TODAY',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onPrimaryContainer)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${date.day} ${_monthName(date.month)} ${date.year}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isPast
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isPast ? FontWeight.w700 : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit_calendar_rounded,
                          size: 14, color: theme.colorScheme.primary),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'SCHEDULE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isPast)
                  Text(
                    'Tap to change',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _weekdayName(int day) {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[day - 1];
  }

  String _monthName(int month) {
    const names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return names[month - 1];
  }
}
// ─────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                size: 36,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 22),

            Text(
              'Nothing scheduled',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Enjoy the free time. Your schedule '
              'is clear for this day.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// ERROR STATE
// ─────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 14),
          const Text('Something went wrong'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
