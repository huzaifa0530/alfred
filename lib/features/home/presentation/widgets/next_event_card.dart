import 'package:alfred/app/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

import '../../../events/domain/entities/event.dart';
class NextEventCard extends StatelessWidget {
  final Event? event;
  final VoidCallback? onTap;

  const NextEventCard({super.key, required this.event, this.onTap});

  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('exam') || t.contains('test')) {
      return Icons.edit_note_rounded;
    }
    if (t.contains('quiz')) return Icons.quiz_rounded;
    if (t.contains('assignment') || t.contains('homework')) {
      return Icons.assignment_rounded;
    }
    if (t.contains('project')) return Icons.dashboard_customize_rounded;
    if (t.contains('class') || t.contains('lecture')) {
      return Icons.school_rounded;
    }
    return Icons.event_rounded;
  }

  String _countdownLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return '${diff}d left';
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(today).inDays;

    final time = TimeOfDay.fromDateTime(date);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    if (difference == 0) return 'Today · $hour:$minute $period';
    if (difference == 1) return 'Tomorrow · $hour:$minute $period';

    return '${date.day}/${date.month}/${date.year} · $hour:$minute $period';
  }

  List<T> applyManualOrder<T>(
  List<T> events,
  int Function(T) getId,
  List<int> manualOrder,
) {
  final manualIndex = {
    for (var i = 0; i < manualOrder.length; i++)
      manualOrder[i]: i,
  };

  final ordered = List<T>.from(events);

  ordered.sort((a, b) {
    final aIndex = manualIndex[getId(a)];
    final bIndex = manualIndex[getId(b)];

    if (aIndex != null && bIndex != null) {
      return aIndex.compareTo(bIndex);
    }

    if (aIndex != null) return -1;
    if (bIndex != null) return 1;

    return 0;
  });

  return ordered;
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (event == null) {
      return const _EmptyNextEvent();
    }

    final icon = _iconForType(event!.type);
    final countdown = _countdownLabel(event!.dueDate);
    final isUrgent = countdown == 'Today' || countdown == 'Overdue';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.78),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.32),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Faint oversized watermark icon for depth.
                Positioned(
                  right: -18,
                  bottom: -22,
                  child: Icon(
                    icon,
                    size: 130,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              'NEXT',
                              style: AppTextStyles.status.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? const Color(0xFFFF9F43)
                                  : Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              countdown,
                              style: AppTextStyles.status.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_outward_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, size: 20, color: Colors.white),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        event!.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headingLarge.copyWith(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _capitalize(event!.type),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 17,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            _formatDate(event!.dueDate),
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
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
      ),
    );
  }
}

class _EmptyNextEvent extends StatelessWidget {
  const _EmptyNextEvent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF28C76F), Color(0xFF48DA8E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are all caught up',
                  style: AppTextStyles.headingSmall.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'No upcoming events.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
