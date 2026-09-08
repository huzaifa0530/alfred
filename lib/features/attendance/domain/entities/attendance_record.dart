enum AttendanceStatus { present, absent, cancelled, noClass }

class AttendanceRecord {
  final int id;
  final int subjectId;
  final int? scheduleId;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime markedAt;
  final String? note;

  // backwards compat - so old code `r.present` still works
  bool get present => status == AttendanceStatus.present;

  AttendanceRecord({
    required this.id,
    required this.subjectId,
    this.scheduleId,
    required this.date,
    required this.status,
    required this.markedAt,
    this.note,
  });

  AttendanceRecord copyWith({AttendanceStatus? status, DateTime? markedAt, String? note, int? scheduleId}) {
    return AttendanceRecord(
      id: id,
      subjectId: subjectId,
      scheduleId: scheduleId ?? this.scheduleId,
      date: date,
      status: status ?? this.status,
      markedAt: markedAt ?? this.markedAt,
      note: note ?? this.note,
    );
  }
}