import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/event.dart';
import '../controllers/events_providers.dart';
import 'set_reminder_sheet.dart';
import 'event_priority_badge.dart';
import 'event_type_icon.dart';

class EventCard extends ConsumerStatefulWidget {
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
  ConsumerState<EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<EventCard> {
  bool _hasReminder = false;

  @override
  void initState() {
    super.initState();
    _checkReminder();
  }

  @override
  void didUpdateWidget(covariant EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.id != widget.event.id) {
      _checkReminder();
    }
  }

  Future<void> _checkReminder() async {
    final info = await ref.read(eventReminderStorageProvider).get(widget.event.id);
    if (mounted) setState(() => _hasReminder = info != null);
  }

  Future<void> _openReminderSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SetReminderSheet(event: widget.event),
    );
    _checkReminder(); // refresh the bell state after the sheet closes
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = widget.event.isOverdue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventTypeIcon(type: widget.event.type),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(width: 4),

                        IconButton(
                          tooltip: _hasReminder ? 'Reminder set' : 'Set reminder',
                          onPressed: _openReminderSheet,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            _hasReminder ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                            size: 20,
                            color: _hasReminder ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),

                        Checkbox(
                          value: widget.event.isCompleted,
                          onChanged: widget.onCompletedChanged == null
                              ? null
                              : (value) {
                                  if (value != null) {
                                    widget.onCompletedChanged!(value);
                                  }
                                },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),

                    if (widget.event.description != null &&
                        widget.event.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.event.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        EventPriorityBadge(priority: widget.event.priority),

                        const SizedBox(width: 8),

                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: isOverdue ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          _formatDueDate(widget.event.dueDate),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOverdue ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
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

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(today).inDays;

    if (difference == 0) return 'Today · ${_time(date)}';
    if (difference == 1) return 'Tomorrow · ${_time(date)}';
    if (difference == -1) return 'Yesterday · ${_time(date)}';

    return '${date.day}/${date.month}/${date.year} · ${_time(date)}';
  }

  String _time(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}