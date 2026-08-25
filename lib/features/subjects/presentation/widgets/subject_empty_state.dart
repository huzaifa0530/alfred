import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

class SubjectEmptyState extends StatelessWidget {
  final VoidCallback onAddSubject;

  const SubjectEmptyState({
    super.key,
    required this.onAddSubject,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          AppDimensions.space32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusXLarge,
                ),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 32,
                color: AppColors.primarySoft,
              ),
            ),

            const SizedBox(
              height: AppDimensions.space20,
            ),

            const Text(
              'No subjects yet',
              style: AppTextStyles.headingMedium,
            ),

            const SizedBox(
              height: AppDimensions.space8,
            ),

            const Text(
              'Add your first subject to start building your academic workspace.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),

            const SizedBox(
              height: AppDimensions.space24,
            ),

            FilledButton.icon(
              onPressed: onAddSubject,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'Add subject',
              ),
            ),
          ],
        ),
      ),
    );
  }
}