import 'package:alfred/features/subjects/presentation/screens/add_subject_screen.dart';
import 'package:alfred/features/subjects/presentation/screens/subject_details_screen.dart';
import 'package:alfred/features/timetable/presentation/controllers/timetable_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../timetable/domain/entities/class_schedule.dart';
import '../../domain/entities/subject.dart';
import '../controllers/subjects_controller.dart';
import '../widgets/subject_empty_state.dart';
import '../widgets/subject_tile.dart';

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  final _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
      color: AppColors.error,
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
    );
  }

  Future<bool> _confirmDeleteSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete subject?'),
        content: Text(
          'This will permanently delete "${subject.name}" and all its notes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return confirm ?? false;
  }

  Future<void> _deleteSubject(Subject subject) async {
    try {
      await ref
          .read(subjectsControllerProvider.notifier)
          .deleteSubject(subject.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${subject.name} deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete subject: $e')));
    }
  }

  void _onEditSubject(Subject subject) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddSubjectScreen(subject: subject)),
    );
  }
  List<Subject> _sortSubjectsByTimetable(
    List<Subject> subjects,
    List<ClassSchedule> schedules,
  ) {
    final now = DateTime.now();

    DateTime combine(int daysFromNow, String hhmm) {
      final parts = hhmm.split(':');

      final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;

      final d = now.add(Duration(days: daysFromNow));

      return DateTime(d.year, d.month, d.day, hour, minute);
    }

    final schedulesBySubject = <int, List<ClassSchedule>>{};

    for (final schedule in schedules) {
      schedulesBySubject
          .putIfAbsent(schedule.subjectId, () => [])
          .add(schedule);
    }

    final currentlyActive = <_SubjectTimetableOrder>[];
    final upcoming = <_SubjectTimetableOrder>[];
    final withoutTimetable = <Subject>[];

    for (final subject in subjects) {
      final subjectSchedules = schedulesBySubject[subject.id];

      if (subjectSchedules == null || subjectSchedules.isEmpty) {
        withoutTimetable.add(subject);
        continue;
      }

      bool isActiveNow = false;
      DateTime? activeEnd;
      DateTime? bestUpcoming;

      for (final schedule in subjectSchedules) {
        int daysUntil = (schedule.weekday - now.weekday) % 7;

        if (daysUntil < 0) {
          daysUntil += 7;
        }

        final start = combine(daysUntil, schedule.startTime);
        final end = combine(daysUntil, schedule.endTime);

        if (daysUntil == 0) {
          // Class happening right now.
          if (!now.isBefore(start) && now.isBefore(end)) {
            isActiveNow = true;

            if (activeEnd == null || end.isBefore(activeEnd)) {
              activeEnd = end;
            }

            continue;
          }

          // Class already finished today -> next week's occurrence.
          if (start.isBefore(now)) {
            final nextWeek = start.add(const Duration(days: 7));

            if (bestUpcoming == null || nextWeek.isBefore(bestUpcoming)) {
              bestUpcoming = nextWeek;
            }

            continue;
          }
        }

        // Upcoming class.
        if (bestUpcoming == null || start.isBefore(bestUpcoming)) {
          bestUpcoming = start;
        }
      }

      if (isActiveNow && activeEnd != null) {
        currentlyActive.add(
          _SubjectTimetableOrder(
            subject: subject,
            time: activeEnd,
            isActive: true,
          ),
        );
      } else if (bestUpcoming != null) {
        upcoming.add(
          _SubjectTimetableOrder(
            subject: subject,
            time: bestUpcoming,
            isActive: false,
          ),
        );
      } else {
        withoutTimetable.add(subject);
      }
    }

    // Currently running first.
    currentlyActive.sort((a, b) => a.time.compareTo(b.time));

    // Then soonest-upcoming.
    upcoming.sort((a, b) => a.time.compareTo(b.time));

    return [
      ...currentlyActive.map((e) => e.subject),
      ...upcoming.map((e) => e.subject),
      ...withoutTimetable,
    ];
  }
  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsControllerProvider);
    final allTimetableAsync = ref.watch(allTimetableProvider);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),

            SliverToBoxAdapter(child: _buildSearch()),

            subjectsAsync.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),

              error: (error, stackTrace) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildError(),
                );
              },

              data: (subjects) {
                final filteredSubjects = _filterSubjects(subjects);

                return allTimetableAsync.when(
                  loading: () {
                    return _buildSubjectsList(filteredSubjects);
                  },
                  error: (_, __) {
                    return _buildSubjectsList(filteredSubjects);
                  },
                  data: (schedules) {
                    final sortedSubjects = _sortSubjectsByTimetable(
                      filteredSubjects,
                      schedules,
                    );

                    return _buildSubjectsList(sortedSubjects);
                  },
                );
              },
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _onAddSubject,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildSubjectsList(List<Subject> subjects) {
    if (subjects.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _searchQuery.isEmpty
            ? SubjectEmptyState(onAddSubject: _onAddSubject)
            : const Center(
                child: Text(
                  'No subjects found',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(
        left: AppDimensions.space8,
        right: AppDimensions.space8,
        bottom: AppDimensions.space32,
      ),
      sliver: SliverList.separated(
        itemCount: subjects.length,
        separatorBuilder: (_, __) {
          return const Divider(indent: 76, endIndent: 8);
        },
        itemBuilder: (context, index) {
          final subject = subjects[index];

          return Dismissible(
            key: ValueKey('subject-${subject.id}'),
            direction: DismissDirection.startToEnd,
            background: _buildDeleteBackground(),
            confirmDismiss: (_) => _confirmDeleteSubject(subject),
            onDismissed: (_) => _deleteSubject(subject),
            child: GestureDetector(
              onLongPress: () => _onEditSubject(subject),
              child: SubjectTile(
                subject: subject,
                onTap: () {
                  _onSubjectTap(subject.id);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space20,
        AppDimensions.space24,
        AppDimensions.space20,
        AppDimensions.space20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subjects', style: AppTextStyles.displayMedium),

                SizedBox(height: AppDimensions.space6),

                Text(
                  'Your academic workspace',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space20,
        0,
        AppDimensions.space20,
        AppDimensions.space20,
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search subjects...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.space32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: AppColors.error,
          ),

          const SizedBox(height: AppDimensions.space16),

          const Text(
            'Unable to load subjects',
            style: AppTextStyles.headingSmall,
          ),

          const SizedBox(height: AppDimensions.space8),

          TextButton(
            onPressed: () {
              ref.invalidate(subjectsControllerProvider);
            },
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  List<Subject> _filterSubjects(List<Subject> subjects) {
    if (_searchQuery.isEmpty) {
      return subjects;
    }

    final query = _searchQuery.toLowerCase();

    return subjects.where((subject) {
      return subject.name.toLowerCase().contains(query) ||
          (subject.code?.toLowerCase().contains(query) ?? false) ||
          (subject.instructor?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  //route forget
  void _onAddSubject() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddSubjectScreen()));
  }

  //route forget
  void _onSubjectTap(int subjectId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubjectDetailsScreen(subjectId: subjectId),
      ),
    );
  }
}
class _SubjectTimetableOrder {
  final Subject subject;
  final DateTime time;
  final bool isActive;

  const _SubjectTimetableOrder({
    required this.subject,
    required this.time,
    required this.isActive,
  });
}