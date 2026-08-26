import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    final weekday = _weekday(now.weekday);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Good ${_greeting(now.hour)}',
          style: theme.textTheme.headlineMedium
              ?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          '$weekday · ${now.day} ${_month(now.month)}',
          style: theme.textTheme.bodyMedium
              ?.copyWith(
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _greeting(int hour) {
    if (hour < 12) {
      return 'morning';
    }

    if (hour < 17) {
      return 'afternoon';
    }

    if (hour < 21) {
      return 'evening';
    }

    return 'night';
  }

  String _weekday(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[day - 1];
  }

  String _month(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }
}