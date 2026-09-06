enum DayAttendanceStatus {
  present,   // green
  absent,    // red
  unmarked,  // class happened but not marked yet — shown amber
  future,    // scheduled class, date hasn't happened yet
  noClass,   // no class that weekday
}