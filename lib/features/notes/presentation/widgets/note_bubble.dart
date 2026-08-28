import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/note.dart';

class NoteBubble extends StatelessWidget {
  final Note note;
  final List<Widget> attachments;
  final VoidCallback? onDelete;
  final VoidCallback? onSummarize;

  const NoteBubble({
    super.key,
    required this.note,
    this.attachments = const [],
    this.onDelete,
    this.onSummarize,
  });

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(note.createdAt);

    return Dismissible(
      key: ValueKey('note-${note.id}'),

      direction: DismissDirection.startToEnd,

      confirmDismiss: (_) async {
        return await _showDeleteConfirmation(context);
      },

      onDismissed: (_) {
        onDelete?.call();
      },

      background: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.space8),
        padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),

      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onLongPress: onSummarize == null ? null : () => onSummarize!(),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            margin: const EdgeInsets.only(bottom: AppDimensions.space8),
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space16,
              AppDimensions.space12,
              AppDimensions.space12,
              AppDimensions.space8,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.only(
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
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
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
                    if (onSummarize != null) ...[
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: AppColors.primarySoft.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                    ],
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
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete note?'),
          content: const Text(
            'This note and its attachments will be permanently removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}