import 'package:alfred/features/notes/presentation/screens/notes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/subject.dart';
import '../controllers/subjects_providers.dart';

class SubjectDetailsScreen extends ConsumerWidget {
  final int subjectId;

  const SubjectDetailsScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(subjectsRepositoryProvider);

    return FutureBuilder<Subject?>(
      future: repository.getSubject(subjectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('Subject not found', style: AppTextStyles.bodyMedium),
            ),
          );
        }

        final subject = snapshot.data!;

        return _SubjectDetailsContent(subject: subject);
      },
    );
  }
}

class _SubjectDetailsContent extends StatelessWidget {
  final Subject subject;

  const _SubjectDetailsContent({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            _SubjectAvatar(subject: subject),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall,
                  ),
                  if (subject.code != null)
                    Text(subject.code!, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildWorkspace(context)),
          _buildComposer(context),
        ],
      ),
    );
  }

  Widget _buildWorkspace(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space20,
        AppDimensions.space20,
        AppDimensions.space20,
        AppDimensions.space20,
      ),
      children: [
        _buildDateDivider('TODAY'),

        const SizedBox(height: AppDimensions.space16),

        _buildWelcomeCard(),

        const SizedBox(height: AppDimensions.space20),

        _buildQuickActions(),

        const SizedBox(height: AppDimensions.space24),
        _buildSection(
          icon: Icons.forum_outlined,
          title: 'Notes',
          subtitle: 'Your explanations, thoughts and study notes',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NotesScreen(
                  subjectId: subject.id,
                  subjectName: subject.name,
                ),
              ),
            );
          },
        ),
        _buildSection(
          icon: Icons.event_note_rounded,
          title: 'Upcoming',
          subtitle: 'Assignments, quizzes and important dates',
          onTap: () {},
        ),

        _buildSection(
          icon: Icons.check_circle_outline_rounded,
          title: 'Attendance',
          subtitle: 'Track your classes and attendance',
          onTap: () {},
        ),

        _buildSection(
          icon: Icons.analytics_outlined,
          title: 'Marks',
          subtitle: 'Quizzes, assignments, labs and exams',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildDateDivider(String text) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space12,
          ),
          child: Text(text, style: AppTextStyles.labelSmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primarySoft,
              size: 21,
            ),
          ),

          const SizedBox(width: AppDimensions.space12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your knowledge space', style: AppTextStyles.headingSmall),
                SizedBox(height: AppDimensions.space6),
                Text(
                  'Save explanations, notes, photos, files and important information for this subject.',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.photo_camera_outlined,
            label: 'Photo',
            onTap: () {},
          ),
        ),
        const SizedBox(width: AppDimensions.space8),
        Expanded(
          child: _QuickAction(
            icon: Icons.attach_file_rounded,
            label: 'File',
            onTap: () {},
          ),
        ),
        const SizedBox(width: AppDimensions.space8),
        Expanded(
          child: _QuickAction(
            icon: Icons.mic_none_rounded,
            label: 'Voice',
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMedium,
                    ),
                  ),
                  child: Icon(icon, color: AppColors.primarySoft, size: 22),
                ),

                const SizedBox(width: AppDimensions.space12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.headingSmall),
                      const SizedBox(height: AppDimensions.space4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.space12,
          AppDimensions.space8,
          AppDimensions.space12,
          AppDimensions.space8,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),

            Expanded(
              child: TextField(
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Write a note...',
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppDimensions.space4),

            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.mic_none_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
          child: Column(
            children: [
              Icon(icon, size: 21, color: AppColors.primarySoft),
              const SizedBox(height: AppDimensions.space6),
              Text(label, style: AppTextStyles.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectAvatar extends StatelessWidget {
  final Subject subject;

  const _SubjectAvatar({required this.subject});

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(subject.name);

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.primarySoft),
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));

    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }

    return name
        .trim()
        .substring(0, name.trim().length >= 2 ? 2 : 1)
        .toUpperCase();
  }
}
