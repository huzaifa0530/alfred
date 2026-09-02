import 'package:alfred/app/router/route_names.dart';
import 'package:alfred/app/theme/app_colors.dart';
import 'package:alfred/app/theme/app_text_styles.dart';
import 'package:alfred/core/database/database_providers.dart';
import 'package:alfred/features/home/presentation/widgets/ask_alfred_sheet.dart';
import 'package:alfred/features/subjects/domain/entities/subject.dart';
import 'package:alfred/features/timetable/domain/entities/class_schedule.dart';
import 'package:alfred/features/timetable/presentation/controllers/timetable_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/home_providers.dart';
import '../widgets/home_header.dart';
import '../widgets/next_event_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recent_subject_card.dart';

class _SubjectScheduleState {
  final Subject subject;
  final DateTime time;

  const _SubjectScheduleState({required this.subject, required this.time});
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  //    @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     ref.read(settingsControllerProvider.notifier).maybeRunAutoBackupOnOpen();
  //   });
  // }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Debug: Print all schedules when home screen loads

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final nextEvent = ref.watch(nextEventProvider);
    final subjects = ref.watch(homeSubjectsProvider);

    final todaySchedulesAsync = ref.watch(todayTimetableProvider);
    final todaySchedules = todaySchedulesAsync.value ?? const <ClassSchedule>[];
    final sortedSubjects = _sortSubjectsByTimetable(subjects, todaySchedules);
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          _AmbientBackground(colorScheme: colorScheme),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _Reveal(
                        index: 0,
                        child: HomeHeader(
                          subjectCount: subjects.length,
                          hasEvent: nextEvent != null,
                        ),
                      ),

                      const SizedBox(height: 18),

                      _Reveal(
                        index: 1,
                        child: _AskAlfredBar(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (_) => const AskAlfredSheet(),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 26),

                      _Reveal(
                        index: 2,
                        child: const _SectionTitle(
                          title: "TODAY'S FOCUS",
                          icon: Icons.bolt_rounded,
                          //  icon: Icons.track_changes_rounded,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _Reveal(
                        index: 3,
                        child: NextEventCard(
                          event: nextEvent,
                          onTap: nextEvent == null
                              ? null
                              : () {
                                  context.push(RouteNames.events);
                                },
                        ),
                      ),

                      const SizedBox(height: 30),

                      _Reveal(
                        index: 4,
                        child: const _SectionTitle(
                          title: 'QUICK ACCESS',
                          icon: Icons.grid_view_rounded,
                        ),
                      ),

                      const SizedBox(height: 12),
                      _Reveal(
                        index: 5,
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,

                          childAspectRatio:
                              MediaQuery.sizeOf(context).width < 600
                              ? 1.35
                              : 1.75,

                          children: [
                            // ─────────────────────────────────────────────
                            // DOMAINS
                            // Subjects / areas / topics Alfred manages
                            // ─────────────────────────────────────────────
                            QuickActionCard(
                              icon: Icons.account_tree_rounded,
                              title: 'Domains',
                              subtitle: 'Areas under Alfred\'s watch',
                              accent: AppColors.primary,
                              onTap: () {
                                context.push(RouteNames.subjects);
                              },
                            ),

                            // ─────────────────────────────────────────────
                            // PRESENCE
                            // Attendance / presence tracking
                            // ─────────────────────────────────────────────
                            QuickActionCard(
                              icon: Icons.fact_check_rounded,
                              title: 'Presence',
                              subtitle: 'Where you need to be',
                              accent: AppColors.primary,
                              onTap: () {
                                context.push(RouteNames.attendance);
                              },
                            ),

                            // ─────────────────────────────────────────────
                            // SCHEDULE
                            // Bruce Wayne's planned engagements
                            // ─────────────────────────────────────────────
                            QuickActionCard(
                              icon: Icons.schedule_rounded,
                              title: 'Schedule',
                              subtitle: 'Your planned engagements',
                              accent: AppColors.primary,
                              onTap: () {
                                context.push(RouteNames.timetable);
                              },
                            ),

                            // ─────────────────────────────────────────────
                            // MISSIONS
                            // Events / deadlines / important commitments
                            // ─────────────────────────────────────────────
                            QuickActionCard(
                              icon: Icons.event_note_rounded,
                              title: 'Missions',
                              subtitle: 'Dates & commitments',
                              accent: AppColors.primary,
                              onTap: () {
                                context.push(RouteNames.events);
                              },
                            ),

                            // ─────────────────────────────────────────────
                            // NEXT MOVE
                            // Immediate task / action
                            // ─────────────────────────────────────────────
                            QuickActionCard(
                              icon: Icons.arrow_forward_rounded,
                              title: 'Next Move',
                              subtitle: 'What deserves your attention',
                              accent: AppColors.primary,
                              onTap: () {
                                context.push('${RouteNames.events}/create');
                              },
                            ),

                            // ─────────────────────────────────────────────
                            // PROGRESS
                            // Marks / achievements / measurable results
                            // ─────────────────────────────────────────────
                            QuickActionCard(
                              icon: Icons.insights_rounded,
                              title: 'Progress',
                              subtitle: 'Measure what you\'ve accomplished',
                              accent: AppColors.primary,
                              onTap: () {
                                context.push(RouteNames.marks);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      _Reveal(
                        index: 6,
                        child: _SectionTitle(
                          title: 'SUBJECTS',
                          icon: Icons.menu_book_rounded,
                          action: subjects.isEmpty ? null : 'View all',
                          onAction: () {
                            context.push(RouteNames.subjects);
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      _Reveal(
                        index: 7,
                        child: subjects.isEmpty
                            ? const _EmptySubjects()
                            : todaySchedulesAsync.when(
                                loading: () => Column(
                                  children: subjects
                                      .take(4)
                                      .map(
                                        (subject) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: RecentSubjectCard(
                                            subject: subject,
                                            onTap: () => context.push(
                                              '${RouteNames.subjects}/${subject.id}',
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                error: (_, __) => Column(
                                  children: subjects
                                      .take(4)
                                      .map(
                                        (subject) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: RecentSubjectCard(
                                            subject: subject,
                                            onTap: () => context.push(
                                              '${RouteNames.subjects}/${subject.id}',
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                data: (todaySchedules) {
                                  final sortedSubjects =
                                      _sortSubjectsByTimetable(
                                        subjects,
                                        todaySchedules,
                                      );
                                  return Column(
                                    children: sortedSubjects
                                        .take(4)
                                        .map(
                                          (subject) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            child: RecentSubjectCard(
                                              subject: subject,
                                              statusLabel: _statusLabelFor(
                                                subject,
                                                todaySchedules,
                                              ),
                                              onTap: () => context.push(
                                                '${RouteNames.subjects}/${subject.id}',
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                              ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Orders subjects so a class happening right now comes first, then
  /// classes coming up later today (soonest first), then everything else
  /// in its original order.
  /// Orders subjects for the Home dashboard:
  ///
  /// 1. Class currently in progress
  /// 2. Upcoming classes today — nearest first
  /// 3. Subjects whose classes have already finished today
  /// 4. Subjects with no class today — alphabetical
  ///
  List<Subject> _sortSubjectsByTimetable(
    List<Subject> subjects,
    List<ClassSchedule> todaySchedules,
  ) {
    DateTime parseTime(String value) {
      final parts = value.split(':');

      final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;

      final now = DateTime.now();

      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    final now = DateTime.now();

    // ============================================================
    // DEBUG — RAW DATA
    // ============================================================

    debugPrint('');
    debugPrint('══════════════════════════════════════════════════════');
    debugPrint('📚 ALFRED SUBJECT ORDER DEBUG');
    debugPrint('══════════════════════════════════════════════════════');
    debugPrint('🕐 Current DateTime : $now');
    debugPrint('📅 Current Weekday  : ${now.weekday}');
    debugPrint('📚 Subjects count   : ${subjects.length}');
    debugPrint('🗓️ Schedules count  : ${todaySchedules.length}');
    debugPrint('');

    debugPrint('──────────── SUBJECTS ────────────');

    for (final subject in subjects) {
      debugPrint('Subject → id=${subject.id} | name="${subject.name}"');
    }

    debugPrint('');

    debugPrint('──────────── TODAY SCHEDULES ────────────');

    for (final schedule in todaySchedules) {
      debugPrint(
        'Schedule → '
        'id=${schedule.id} | '
        'subjectId=${schedule.subjectId} | '
        'weekday=${schedule.weekday} | '
        'start=${schedule.startTime} | '
        'end=${schedule.endTime} | '
        'room=${schedule.room} | '
        'active=${schedule.isActive}',
      );
    }

    debugPrint('');

    // ============================================================
    // GROUP SCHEDULES BY SUBJECT
    // ============================================================

    final scheduleBySubject = <int, List<ClassSchedule>>{};

    for (final schedule in todaySchedules) {
      scheduleBySubject
          .putIfAbsent(schedule.subjectId, () => <ClassSchedule>[])
          .add(schedule);
    }

    debugPrint('──────────── SUBJECT → SCHEDULE MAP ────────────');

    for (final entry in scheduleBySubject.entries) {
      debugPrint(
        'subjectId=${entry.key} '
        '→ ${entry.value.length} schedule(s)',
      );

      for (final schedule in entry.value) {
        debugPrint('   ${schedule.startTime} → ${schedule.endTime}');
      }
    }

    debugPrint('');

    // ============================================================
    // SORTING GROUPS
    // ============================================================

    final currentlyActive = <_SubjectScheduleState>[];
    final upcoming = <_SubjectScheduleState>[];
    final finished = <_SubjectScheduleState>[];
    final noSchedule = <Subject>[];

    for (final subject in subjects) {
      final schedules = scheduleBySubject[subject.id];

      debugPrint('────────────────────────────────────');
      debugPrint(
        '🔎 CHECKING SUBJECT: '
        '${subject.name} '
        '(id=${subject.id})',
      );

      if (schedules == null || schedules.isEmpty) {
        debugPrint('   ❌ NO SCHEDULE FOUND');
        noSchedule.add(subject);
        continue;
      }

      ClassSchedule? activeSchedule;
      ClassSchedule? nextSchedule;
      ClassSchedule? lastFinishedSchedule;

      DateTime? activeEnd;
      DateTime? nextStart;
      DateTime? finishedEnd;

      for (final schedule in schedules) {
        final start = parseTime(schedule.startTime);
        final end = parseTime(schedule.endTime);

        debugPrint('   🗓️ ${schedule.startTime} → ${schedule.endTime}');

        debugPrint('      start=$start | end=$end');

        final isActive = !now.isBefore(start) && now.isBefore(end);

        debugPrint('      isActive=$isActive');

        if (isActive) {
          debugPrint('      🟢 CURRENT CLASS');

          if (activeEnd == null || end.isBefore(activeEnd)) {
            activeSchedule = schedule;
            activeEnd = end;
          }

          continue;
        }

        if (!start.isBefore(now)) {
          debugPrint('      🔵 UPCOMING CLASS');

          if (nextStart == null || start.isBefore(nextStart)) {
            nextSchedule = schedule;
            nextStart = start;
          }

          continue;
        }

        debugPrint('      ⚪ FINISHED CLASS');

        if (finishedEnd == null || end.isAfter(finishedEnd)) {
          lastFinishedSchedule = schedule;
          finishedEnd = end;
        }
      }

      if (activeSchedule != null && activeEnd != null) {
        debugPrint('   👉 GROUP: CURRENT');
        debugPrint('   👉 END: $activeEnd');

        currentlyActive.add(
          _SubjectScheduleState(subject: subject, time: activeEnd),
        );
      } else if (nextSchedule != null && nextStart != null) {
        debugPrint('   👉 GROUP: UPCOMING');
        debugPrint('   👉 START: $nextStart');

        upcoming.add(_SubjectScheduleState(subject: subject, time: nextStart));
      } else if (lastFinishedSchedule != null && finishedEnd != null) {
        debugPrint('   👉 GROUP: FINISHED');
        debugPrint('   👉 END: $finishedEnd');

        finished.add(
          _SubjectScheduleState(subject: subject, time: finishedEnd),
        );
      } else {
        debugPrint('   👉 GROUP: NO SCHEDULE');
        noSchedule.add(subject);
      }
    }

    // ============================================================
    // SORT EACH GROUP
    // ============================================================

    currentlyActive.sort((a, b) => a.time.compareTo(b.time));

    upcoming.sort((a, b) => a.time.compareTo(b.time));

    finished.sort((a, b) => b.time.compareTo(a.time));

    noSchedule.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    // ============================================================
    // FINAL ORDER
    // ============================================================

    final result = [
      ...currentlyActive.map((item) => item.subject),
      ...upcoming.map((item) => item.subject),
      ...finished.map((item) => item.subject),
      ...noSchedule,
    ];

    debugPrint('');
    debugPrint('══════════════════════════════════════════════════════');
    debugPrint('🏁 FINAL SUBJECT ORDER');
    debugPrint('══════════════════════════════════════════════════════');

    for (var i = 0; i < result.length; i++) {
      final subject = result[i];

      String group = 'UNKNOWN';

      if (currentlyActive.any((x) => x.subject.id == subject.id)) {
        group = 'CURRENT';
      } else if (upcoming.any((x) => x.subject.id == subject.id)) {
        group = 'UPCOMING';
      } else if (finished.any((x) => x.subject.id == subject.id)) {
        group = 'FINISHED';
      } else if (noSchedule.any((x) => x.id == subject.id)) {
        group = 'NO SCHEDULE';
      }

      debugPrint(
        '${i + 1}. ${subject.name} '
        '(id=${subject.id}) → $group',
      );
    }

    debugPrint('══════════════════════════════════════════════════════');
    debugPrint('');

    return result;
  }

  /// "Now" if the subject has a class in progress right now, a formatted
  /// start time (e.g. "2:30 PM") if it has one coming up later today,
  /// or null if nothing's scheduled today.
  String? _statusLabelFor(Subject subject, List<ClassSchedule> todaySchedules) {
    DateTime parseTime(String hhmm) {
      final parts = hhmm.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    String formatTime(DateTime dt) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }

    final now = DateTime.now();
    final subjectSchedules = todaySchedules.where(
      (s) => s.subjectId == subject.id,
    );

    DateTime? ongoingEnd;
    DateTime? nextStart;

    for (final schedule in subjectSchedules) {
      final start = parseTime(schedule.startTime);
      final end = parseTime(schedule.endTime);

      if (now.isAfter(start) && now.isBefore(end)) {
        if (ongoingEnd == null || end.isBefore(ongoingEnd)) ongoingEnd = end;
      } else if (start.isAfter(now)) {
        if (nextStart == null || start.isBefore(nextStart)) nextStart = start;
      }
    }

    if (ongoingEnd != null) return 'Now';
    if (nextStart != null) return formatTime(nextStart);
    return null;
  }
}

/// Soft, layered gradient wash that sits behind the whole screen so the
/// glass bottom nav and cards have something with depth to sit on top of.
class _AmbientBackground extends StatelessWidget {
  final ColorScheme colorScheme;

  const _AmbientBackground({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(color: colorScheme.surface),
        child: Stack(
          children: [
            Positioned(
              top: -140,
              right: -100,
              child: _Blob(
                size: 320,
                color: colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
            Positioned(
              top: 180,
              left: -140,
              child: _Blob(
                size: 260,
                color: const Color(0xFF00B8A9).withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

/// Placeholder entry point for the upcoming prompt / voice-to-text
/// automation feature — visually staged now so it slots straight in later.
class _AskAlfredBar extends StatelessWidget {
  final VoidCallback onTap;

  const _AskAlfredBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 19,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  'How may I assist you, sir?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontFamily: 'Cinzel',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              Icon(
                Icons.mic_none_rounded,
                size: 19,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? action;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.icon,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        if (icon != null) ...[
          Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: AppTextStyles.headingSmall.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        if (action != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action!,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptySubjects extends StatelessWidget {
  const _EmptySubjects();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.menu_book_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add your subjects to start building your academic workspace.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: () => context.push(RouteNames.subjects),
            child: const Text('Browse subjects'),
          ),
        ],
      ),
    );
  }
}

/// Lightweight fade + rise-in entrance for the list of sections. Later
/// items settle in slightly after earlier ones for a cascading feel,
/// without needing an AnimationController per section.
class _Reveal extends StatelessWidget {
  final int index;
  final Widget child;

  const _Reveal({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + (index * 70)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
