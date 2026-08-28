import 'package:flutter/material.dart';

import '../../domain/entities/mark_component.dart';

class MarksComponentHeader extends StatelessWidget {
  final MarkComponent component;
  final double width;

  const MarksComponentHeader({
    super.key,
    required this.component,
    this.width = 105,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      height: 82,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant
                .withValues(alpha: 0.4),
          ),
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant
                .withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            component.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '${_formatMaxMarks(component.maxMarks)} marks',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMaxMarks(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }
}