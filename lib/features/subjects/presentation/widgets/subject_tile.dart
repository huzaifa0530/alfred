import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/subject.dart';

class SubjectTile extends StatelessWidget {
  final Subject subject;
  final VoidCallback? onTap;

  const SubjectTile({
    super.key,
    required this.subject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(subject.name);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusLarge,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SubjectAvatar(
                initials: initials,
                color: _parseColor(subject.color),
              ),

              const SizedBox(
                width: AppDimensions.space16,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject name + course code
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            subject.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headingSmall,
                          ),
                        ),

                        if (subject.code != null &&
                            subject.code!.trim().isNotEmpty) ...[
                          const SizedBox(width: 8),

                          _CourseCodeBadge(
                            code: subject.code!,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(
                      height: AppDimensions.space8,
                    ),

                    _buildMetadata(),
                  ],
                ),
              ),

              const SizedBox(
                width: AppDimensions.space8,
              ),

              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    final instructor = subject.instructor?.trim();
    final room = subject.room?.trim();

    final hasInstructor =
        instructor != null && instructor.isNotEmpty;

    final hasRoom =
        room != null && room.isNotEmpty;

    if (!hasInstructor && !hasRoom) {
      return const Text(
        'No additional information',
        style: AppTextStyles.bodySmall,
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        if (hasInstructor)
          _MetadataItem(
            icon: Icons.person_outline_rounded,
            text: instructor!,
          ),

        if (hasRoom)
          _MetadataItem(
            icon: Icons.location_on_outlined,
            text: 'Room $room',
          ),
      ],
    );
  }

  String _getInitials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return '?';
    }

    if (words.length == 1) {
      return words.first.substring(
        0,
        words.first.length >= 2 ? 2 : 1,
      ).toUpperCase();
    }

    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }

  Color _parseColor(String? value) {
    if (value == null || value.isEmpty) {
      return AppColors.primary;
    }

    try {
      final hex = value.replaceFirst('#', '');

      final normalized = hex.length == 6
          ? 'FF$hex'
          : hex;

      return Color(
        int.parse(normalized, radix: 16),
      );
    } catch (_) {
      return AppColors.primary;
    }
  }
}

class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetadataItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 240,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 15,
              color: AppColors.textMuted,
            ),
          ),

          const SizedBox(width: 5),

          Flexible(
            child: Text(
              text,
              softWrap: true,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCodeBadge extends StatelessWidget {
  final String code;

  const _CourseCodeBadge({
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        code,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _SubjectAvatar extends StatelessWidget {
  final String initials;
  final Color color;

  const _SubjectAvatar({
    required this.initials,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusMedium,
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.labelLarge.copyWith(
          color: color,
          fontSize: 15,
        ),
      ),
    );
  }
}