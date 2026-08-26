import 'package:flutter/material.dart';

import '../../../events/domain/entities/event.dart';

class NextEventCard extends StatelessWidget {
  final Event? event;
  final VoidCallback? onTap;

  const NextEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (event == null) {
      return _EmptyNextEvent();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme
                .colorScheme
                .primaryContainer,
            borderRadius:
                BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme
                          .colorScheme
                          .onPrimaryContainer
                          .withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        100,
                      ),
                    ),
                    child: Text(
                      'NEXT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: 1,
                        color: theme
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Icon(
                    Icons.arrow_outward_rounded,
                    color: theme
                        .colorScheme
                        .onPrimaryContainer,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                event!.title,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: theme
                      .colorScheme
                      .onPrimaryContainer,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                _capitalize(event!.type),
                style: TextStyle(
                  fontSize: 14,
                  color: theme
                      .colorScheme
                      .onPrimaryContainer
                      .withValues(
                    alpha: 0.70,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 17,
                    color: theme
                        .colorScheme
                        .onPrimaryContainer,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _formatDate(event!.dueDate),
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,
                      color: theme
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;

    return value[0].toUpperCase() +
        value.substring(1);
  }

  String _formatDate(DateTime date) {
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

    final time =
        TimeOfDay.fromDateTime(date);

    final hour = time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.period == DayPeriod.am
            ? 'AM'
            : 'PM';

    if (difference == 0) {
      return 'Today · $hour:$minute $period';
    }

    if (difference == 1) {
      return 'Tomorrow · $hour:$minute $period';
    }

    return '${date.day}/${date.month}/${date.year} · '
        '$hour:$minute $period';
  }
}

class _EmptyNextEvent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme
            .colorScheme
            .surfaceContainer,
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: theme
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme
                  .colorScheme
                  .surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'You are all caught up',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'No upcoming events.',
                  style: TextStyle(
                    fontSize: 13,
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