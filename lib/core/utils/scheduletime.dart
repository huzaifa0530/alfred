String normalizeScheduleTime(String value) {
  var input = value.trim().toUpperCase();

  // Convert formats like:
  // 9 AM     -> 09:00
  // 9:00 AM  -> 09:00
  // 1 PM     -> 13:00
  // 1:30 PM  -> 13:30

  final amPmMatch = RegExp(
    r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)$',
  ).firstMatch(input);

  if (amPmMatch != null) {
    var hour = int.parse(amPmMatch.group(1)!);
    final minute = int.tryParse(amPmMatch.group(2) ?? '00') ?? 0;
    final period = amPmMatch.group(3)!;

    if (hour == 12) {
      hour = 0;
    }

    if (period == 'PM') {
      hour += 12;
    }

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  // Already 24-hour format:
  // 9:00  -> 09:00
  // 09:00 -> 09:00
  // 13:00 -> 13:00

  final twentyFourHourMatch = RegExp(
    r'^(\d{1,2}):(\d{1,2})$',
  ).firstMatch(input);

  if (twentyFourHourMatch != null) {
    final hour = int.parse(twentyFourHourMatch.group(1)!);
    final minute = int.parse(twentyFourHourMatch.group(2)!);

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw FormatException(
        'Invalid timetable time: $value',
      );
    }

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  throw FormatException(
    'Unsupported timetable time format: $value',
  );
}