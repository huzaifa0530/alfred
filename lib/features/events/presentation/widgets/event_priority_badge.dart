import 'package:flutter/material.dart';

class EventPriorityBadge extends StatelessWidget {
  final String priority;

  const EventPriorityBadge({
    super.key,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final normalized =
        priority.toLowerCase();

    final IconData icon;
    final String label;

    switch (normalized) {
      case 'high':
        icon = Icons.priority_high_rounded;
        label = 'HIGH';
        break;

      case 'low':
        icon = Icons.keyboard_arrow_down_rounded;
        label = 'LOW';
        break;

      default:
        icon = Icons.remove_rounded;
        label = 'NORMAL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}