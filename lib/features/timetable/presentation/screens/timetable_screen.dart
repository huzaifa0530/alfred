import 'package:alfred/app/router/route_names.dart';
import 'package:alfred/features/subjects/presentation/controllers/subjects_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../subjects/presentation/controllers/subjects_providers.dart';
import '../controllers/timetable_providers.dart';
import '../widgets/class_card.dart';
import '../widgets/day_selector.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  int _selectedDay = DateTime.now().weekday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      onTodayPressed: () {
                        setState(() {
                          _selectedDay = DateTime.now().weekday;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    DaySelector(
                      selectedDay: _selectedDay,
                      onDayChanged: (day) {
                        setState(() {
                          _selectedDay = day;
                        });
                      },
                    ),

                    const SizedBox(height: 28),

                    _DayHeading(weekday: _selectedDay),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            schedulesAsync.when(
              loading: () {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              },

              error: (error, stack) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    onRetry: () {
                      ref.invalidate(timetableForDayProvider(_selectedDay));
                    },
                  ),
                );
              },

              data: (schedules) {
                final subjects = subjectsAsync.maybeWhen(
                  data: (items) => items,
                  orElse: () => const [],
                );

                String subjectName(int subjectId) {
                  for (final subject in subjects) {
                    if (subject.id == subjectId) {
                      return subject.name;
                    }
                  }

                  return 'Unknown subject';
                }

                if (schedules.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList.separated(
                    itemCount: schedules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final schedule = schedules[index];

                      return ClassCard(
                        schedule: schedule,
                        subjectName: subjectName(schedule.subjectId),
                        onTap: () {
                          // Edit class will be added
                          // in the next iteration.
                        },
                        onDelete: () async {
                          await ref
                              .read(timetableRepositoryProvider)
                              .deleteSchedule(schedule.id);
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
        onPressed: () {
          context.push('${RouteNames.timetable}/create');
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add class'),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onTodayPressed;

  const _Header({required this.onTodayPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Timetable',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your weekly rhythm.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        Material(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onTodayPressed,
            borderRadius: BorderRadius.circular(15),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.today_outlined),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayHeading extends StatelessWidget {
  final int weekday;

  const _DayHeading({required this.weekday});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final date = _dateForWeekday(weekday);

    final dayName = _weekdayName(weekday);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${date.day} ${_monthName(date.month)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        Text(
          'SCHEDULE',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  DateTime _dateForWeekday(int weekday) {
    final today = DateTime.now();

    return today.add(Duration(days: weekday - today.weekday));
  }

  String _weekdayName(int day) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return names[day - 1];
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return names[month - 1];
  }
}

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

String _weekdayName(int day) {
  const names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  return names[day - 1];
}

const _RoutePaths timetableRoutePaths = _RoutePaths();

class _RoutePaths {
  const _RoutePaths();

  String get timetable => '/timetable';
}
