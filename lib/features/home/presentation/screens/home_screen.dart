import 'package:alfred/app/router/route_names.dart';
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

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final nextEvent = ref.watch(nextEventProvider);
    final subjects = ref.watch(homeSubjectsProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                20,
                24,
                20,
                40,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    const HomeHeader(),

                    const SizedBox(height: 28),

                    NextEventCard(
                      event: nextEvent,
                      onTap: nextEvent == null
                          ? null
                          : () {
                              context.push(
                                RouteNames.events,
                              );
                            },
                    ),

                    const SizedBox(height: 30),

                    const _SectionTitle(
                      title: 'QUICK ACCESS',
                    ),

                    const SizedBox(height: 12),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.8,
                      children: [
                        QuickActionCard(
                          icon:
                              Icons.menu_book_outlined,
                          title: 'Subjects',
                          subtitle:
                              '${subjects.length} subjects',
                          onTap: () {
                            context.push(
                              RouteNames.subjects,
                            );
                          },
                        ),

                        QuickActionCard(
                          icon: Icons
                              .calendar_month_outlined,
                          title: 'Timetable',
                          subtitle:
                              'Your class schedule',
                          onTap: () {
                            context.push(
                              RouteNames.timetable,
                            );
                          },
                        ),

                        QuickActionCard(
                          icon:
                              Icons.event_outlined,
                          title: 'Events',
                          subtitle:
                              'Deadlines & tasks',
                          onTap: () {
                            context.push(
                              RouteNames.events,
                            );
                          },
                        ),

                        QuickActionCard(
                          icon:
                              Icons.add_task_rounded,
                          title: 'Add',
                          subtitle:
                              'Create event',
                          onTap: () {
                            context.push(
                              '${RouteNames.events}/create',
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    _SectionTitle(
                      title: 'SUBJECTS',
                      action: subjects.isEmpty
                          ? null
                          : 'View all',
                      onAction: () {
                        context.push(
                          RouteNames.subjects,
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    if (subjects.isEmpty)
                      const _EmptySubjects()
                    else
                      ...subjects.take(4).map(
                        (subject) => Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child:
                              RecentSubjectCard(
                            subject: subject,
                            onTap: () {
                              context.push(
                                '${RouteNames.subjects}/${subject.id}',
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color:
                theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.menu_book_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add your subjects to start building your academic workspace.',
              style: TextStyle(
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}