import 'package:flutter/material.dart';

import '../../domain/entities/event.dart';
import 'event_priority_badge.dart';
import 'event_type_icon.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onCompletedChanged;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onCompletedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final isOverdue =
        event.isOverdue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(24),
        child: Container(
          padding:
              const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme
                .colorScheme
                .surfaceContainer,
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color: theme
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              EventTypeIcon(
                type: event.type,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Checkbox(
                          value:
                              event.isCompleted,
                          onChanged:
                              onCompletedChanged == null
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        onCompletedChanged!(value);
                                      }
                                    },
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              6,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (event.description !=
                            null &&
                        event.description!
                            .trim()
                            .isNotEmpty) ...[
                      const SizedBox(height: 3),

                      Text(
                        event.description!,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        EventPriorityBadge(
                          priority:
                              event.priority,
                        ),

                        const SizedBox(width: 8),

                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: isOverdue
                              ? theme
                                  .colorScheme
                                  .error
                              : theme
                                  .colorScheme
                                  .onSurfaceVariant,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          _formatDueDate(
                            event.dueDate,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600,
                            color: isOverdue
                                ? theme
                                    .colorScheme
                                    .error
                                : theme
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate(
    DateTime date,
  ) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final target = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference =
        target.difference(today).inDays;

    if (difference == 0) {
      return 'Today · ${_time(date)}';
    }

    if (difference == 1) {
      return 'Tomorrow · ${_time(date)}';
    }

    if (difference == -1) {
      return 'Yesterday · ${_time(date)}';
    }

    return '${date.day}/${date.month}/${date.year} · ${_time(date)}';
  }

  String _time(DateTime date) {
    final hour =
        date.hour % 12 == 0
            ? 12
            : date.hour % 12;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}