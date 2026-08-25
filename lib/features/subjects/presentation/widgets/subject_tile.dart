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
                    Text(
                      subject.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall,
                    ),

                    const SizedBox(
                      height: AppDimensions.space4,
                    ),

                    _buildSubtitle(),
                  ],
                ),
              ),

              const SizedBox(
                width: AppDimensions.space12,
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

  Widget _buildSubtitle() {
    final details = <String>[
      if (subject.code != null) subject.code!,
      if (subject.instructor != null) subject.instructor!,
      if (subject.room != null) 'Room ${subject.room!}',
    ];

    if (details.isEmpty) {
      return const Text(
        'No additional information',
        style: AppTextStyles.bodySmall,
      );
    }

    return Text(
      details.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodyMedium,
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