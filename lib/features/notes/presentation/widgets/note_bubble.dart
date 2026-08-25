import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/note.dart';

class NoteBubble extends StatelessWidget {
  final Note note;
  final List<Widget> attachments;
  final VoidCallback? onDelete;
  const NoteBubble({
    super.key,
    required this.note,
    this.attachments = const [],
    this.onDelete,
  });
  @override
  Widget build(BuildContext context) {
    final time = _formatTime(note.createdAt);

    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onLongPress: onDelete,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          margin: const EdgeInsets.only(bottom: AppDimensions.space8),
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.space16,
            AppDimensions.space12,
            AppDimensions.space12,
            AppDimensions.space8,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (note.content.trim().isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    note.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),

              if (attachments.isNotEmpty) ...[
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(spacing: 8, runSpacing: 8, children: attachments),
                ),
              ],

              const SizedBox(height: AppDimensions.space6),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time, style: AppTextStyles.labelSmall),

                  const SizedBox(width: 4),

                  const Icon(
                    Icons.done_all_rounded,
                    size: 15,
                    color: AppColors.primarySoft,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;

    final minute = dateTime.minute.toString().padLeft(2, '0');

    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}
