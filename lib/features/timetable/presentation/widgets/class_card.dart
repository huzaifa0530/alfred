import 'package:flutter/material.dart';

import '../../domain/entities/class_schedule.dart';

class ClassCard extends StatelessWidget {
  final ClassSchedule schedule;
  final String subjectName;
  final VoidCallback? onTap;
  final Future<void> Function()? onDelete;
  final VoidCallback? onEdit;

  const ClassCard({
    super.key,
    required this.schedule,
    required this.subjectName,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(schedule.id),

      // SWIPE RIGHT
      direction: onDelete == null
          ? DismissDirection.none
          : DismissDirection.startToEnd,

      confirmDismiss: (_) async {
        if (onDelete == null) {
          return false;
        }

        final confirmed = await _confirmDelete(context);

        if (!confirmed) {
          return false;
        }

        await onDelete!.call();

        return true;
      },

      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),

      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // ─────────────────────────
                // TIME
                // ─────────────────────────
                SizedBox(
                  width: 74,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.startTime,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        schedule.endTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─────────────────────────
                // VERTICAL LINE
                // ─────────────────────────
                Container(
                  width: 3,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(width: 16),

                // ─────────────────────────
                // CLASS INFORMATION
                // ─────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Row(
                        children: [
                          if (schedule.room != null &&
                              schedule.room!.isNotEmpty) ...[
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                schedule.room!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],

                          if (schedule.teacher != null &&
                              schedule.teacher!.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                schedule.teacher!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // ─────────────────────────
                // EDIT
                // ─────────────────────────
                if (onEdit != null)
                  IconButton(
                    tooltip: 'Edit class',
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 19,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete class?'),
          content: Text('Remove "$subjectName" from your timetable?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
