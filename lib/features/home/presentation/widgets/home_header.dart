import 'package:alfred/app/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// The greeting hero used at the top of Home. Time-aware, with a short
/// remark that reacts to whether there's something on the calendar or the
/// workspace is still empty — a little bit of "Alfred" personality rather
/// than a flat "Good morning" label.
///
class HomeHeader extends StatelessWidget {
  final int subjectCount;
  final bool hasEvent;

  const HomeHeader({super.key, this.subjectCount = 0, this.hasEvent = false});

  String _greeting(int hour) {
    if (hour < 5) return 'Burning the midnight oil';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Working late';
  }

  String get _remark {
    if (hasEvent) {
      return "Something awaits on the calendar, Master Wayne — best not keep it waiting.";
    }
    if (subjectCount == 0) {
      return "The workspace stands quite empty, sir. Shall we give it purpose?";
    }
    return "Everything's in order, Master Wayne. Where shall we begin?";
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6C63FF), Color(0xFF867AFF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'A',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_weekday(now.weekday)} · ${now.day} ${_month(now.month)}'
                    .toUpperCase(),
                style: AppTextStyles.system.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _greeting(now.hour),
                style: AppTextStyles.displayMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _remark,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
