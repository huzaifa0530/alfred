import 'package:flutter/material.dart';

class DaySelector extends StatelessWidget {
  final int selectedDay;
  final ValueChanged<int> onDayChanged;

  const DaySelector({
    super.key,
    required this.selectedDay,
    required this.onDayChanged,
  });

  static const _days = [
    (1, 'Mon'),
    (2, 'Tue'),
    (3, 'Wed'),
    (4, 'Thu'),
    (5, 'Fri'),
    (6, 'Sat'),
    (7, 'Sun'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        for (final day in _days) ...[
          if (day != _days.first)
            const SizedBox(width: 8),
          Expanded(
            child: _DayButton(
              label: day.$2,
              selected: day.$1 == selectedDay,
              onTap: () => onDayChanged(day.$1),
              theme: theme,
            ),
          ),
        ],
      ],
    );
  }
}

class _DayButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _DayButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
