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


