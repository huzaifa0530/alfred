/// Strips time-of-day so DB date comparisons are exact-match safe.
DateTime normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

/// Same logic your `_DayHeading` widget already uses to resolve a
/// weekday into an actual calendar date. Centralized here so the
/// timetable header and attendance marking always agree on "today's
/// instance of this weekday".
DateTime dateForWeekday(int weekday) {
  final today = DateTime.now();
  final resolved = today.add(Duration(days: weekday - today.weekday));
  return normalizeDate(resolved);
}


/// Parses a "HH:mm" (24-hour) string and returns a 12-hour display string
/// like "2:30 PM". Safe to call even if the value is already oddly formatted.
String formatTimeOfDayString(String rawTime) {
  final parts = rawTime.split(':');
  if (parts.length < 2) return rawTime; // fallback, don't crash on bad data

  final hour24 = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1].split(' ').first); // strips any trailing AM/PM if present
  if (hour24 == null || minute == null) return rawTime;

  final period = hour24 >= 12 ? 'PM' : 'AM';
  var hour12 = hour24 % 12;
  if (hour12 == 0) hour12 = 12;

  final minuteStr = minute.toString().padLeft(2, '0');
  return '$hour12:$minuteStr $period';
}