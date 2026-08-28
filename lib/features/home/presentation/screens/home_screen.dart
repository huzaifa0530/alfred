import 'package:alfred/app/router/route_names.dart';
import 'package:alfred/app/theme/app_text_styles.dart';
import 'package:alfred/features/home/presentation/widgets/ask_alfred_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/home_providers.dart';
import '../widgets/home_header.dart';
import '../widgets/next_event_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recent_subject_card.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final nextEvent = ref.watch(nextEventProvider);
    final subjects = ref.watch(homeSubjectsProvider);

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

                          // Taller cards on smaller screens.
                          childAspectRatio:
                              MediaQuery.sizeOf(context).width < 600
                              ? 1.35
                              : 1.75,

                          children: [
                            QuickActionCard(
                              icon: Icons.auto_stories_rounded,
                              title: 'Subjects',
                              subtitle: '${subjects.length} subjects',
                              accent: const Color(0xFF6C63FF),
                              onTap: () {
                                context.push(RouteNames.subjects);
                              },
                            ),

                            QuickActionCard(
                              icon: Icons.fact_check_rounded,
                              title: 'Attendance',
                              subtitle: 'Track your attendance',
                              accent: const Color(0xFFEE5A6F),
                              onTap: () {
                                context.push(RouteNames.attendance);
                              },
                            ),

                            QuickActionCard(
                              icon: Icons.calendar_month_rounded,
                              title: 'Timetable',
                              subtitle: 'Your class schedule',
                              accent: const Color(0xFF00B8A9),
                              onTap: () {
                                context.push(RouteNames.timetable);
                              },
                            ),

                            QuickActionCard(
                              icon: Icons.event_available_rounded,
                              title: 'Events',
                              subtitle: 'Deadlines & tasks',
                              accent: const Color(0xFF7367F0),
                              onTap: () {
                                context.push(RouteNames.events);
                              },
                            ),

                            QuickActionCard(
                              icon: Icons.add_task_rounded,
                              title: 'Add',
                              subtitle: 'Create event',
                              accent: const Color(0xFF28C76F),
                              onTap: () {
                                context.push('${RouteNames.events}/create');
                              },
                            ),

                            QuickActionCard(
                              icon: Icons.query_stats_rounded,
                              title: 'Marks',
                              subtitle: 'Track your assessments',
                              accent: const Color(0xFFFF9F43),
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
                            : Column(
                                children: subjects
                                    .take(4)
                                    .map(
                                      (subject) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: RecentSubjectCard(
                                          subject: subject,
                                          onTap: () {
                                            context.push(
                                              '${RouteNames.subjects}/${subject.id}',
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                    .toList(),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                  'Ask Alfred anything…',
                  style: AppTextStyles.bodyMedium.copyWith(
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
