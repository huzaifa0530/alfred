import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

class NoteEmptyState extends StatelessWidget {
  const NoteEmptyState({
    super.key,
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
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 30,
                color: AppColors.primarySoft,
              ),
            ),

            const SizedBox(
              height: AppDimensions.space16,
            ),

            const Text(
              'Nothing here yet',
              style: AppTextStyles.headingSmall,
            ),

            const SizedBox(
              height: AppDimensions.space8,
            ),

            const Text(
              'Write your first note and keep it here for later.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}