import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../subjects/domain/entities/subject.dart';
import '../../../subjects/presentation/controllers/subjects_controller.dart';
import '../../../subjects/presentation/controllers/subjects_providers.dart';

import '../controllers/marks_providers.dart';
import '../widgets/add_mark_component_sheet.dart';
import '../widgets/marks_grid.dart';

class MarksScreen extends ConsumerWidget {
  const MarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final subjectsAsync = ref.watch(subjectsControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ==================================================
            // HEADER
            // ==================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Marks',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Track quizzes, assignments, exams and projects.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ADD COMPONENT
                    IconButton.filledTonal(
                      tooltip: 'Add assessment',
                      onPressed: () {
                        _showAddComponentSheet(context, ref);
                      },
                      icon: Icon(
                        Icons.add_rounded,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // SMALL SUMMARY
            // ==================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: _MarksInfoCard(),
              ),
            ),

            // ==================================================
            // SUBJECTS
            // ==================================================
            subjectsAsync.when(
              loading: () {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              },

              error: (error, stack) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Unable to load subjects',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                );
              },

              data: (subjects) {
                if (subjects.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptySubjectsState(),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _SubjectMarksSection(subject: subjects[index]),
                      );
                    }, childCount: subjects.length),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddComponentSheet(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.read(subjectsControllerProvider);

    subjectsAsync.whenData((subjects) {
      if (subjects.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Add a subject first.')));

        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) {
          return AddMarkComponentSheet(subjects: subjects);
        },
      );
    });
  }
}

// ============================================================
// INFO CARD
// ============================================================

class _MarksInfoCard extends StatelessWidget {
  const _MarksInfoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.assessment_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your assessments',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Tap any mark to enter or update it.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

// ============================================================
// SUBJECT SECTION
// ============================================================

class _SubjectMarksSection extends ConsumerWidget {
  final Subject subject;

  const _SubjectMarksSection({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final componentsAsync = ref.watch(
      subjectMarkComponentsProvider(subject.id),
    );

    final marksAsync = ref.watch(subjectMarksProvider(subject.id));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SUBJECT HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.menu_book_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    subject.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),

          // GRID
          componentsAsync.when(
            loading: () {
              return const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              );
            },

            error: (error, stack) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load assessments.',
                  style: theme.textTheme.bodySmall,
                ),
              );
            },

            data: (components) {
              if (components.isEmpty) {
                return _NoComponentsState(subject: subject);
              }

              return marksAsync.when(
                loading: () {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()),
                  );
                },

                error: (error, stack) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Unable to load marks.',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },

                data: (marks) {
                  return MarksGrid(
                    subject: subject,
                    components: components,
                    marks: marks,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NO COMPONENTS
// ============================================================
class _NoComponentsState extends StatelessWidget {
  final Subject subject;

  const _NoComponentsState({
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'No assessments added yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          TextButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                builder: (_) {
                  return AddMarkComponentSheet(
                    subjects: [subject],
                  );
                },
              );
            },
            icon: const Icon(
              Icons.add_rounded,
              size: 18,
            ),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
// ============================================================
// EMPTY SUBJECTS
// ============================================================

class _EmptySubjectsState extends StatelessWidget {
  const _EmptySubjectsState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                Icons.menu_book_outlined,
                size: 36,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'No subjects yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Add your subjects first, then '
              'you can start entering marks.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
