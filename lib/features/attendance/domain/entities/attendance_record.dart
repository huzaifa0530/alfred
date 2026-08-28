class AttendanceRecord {
  final int id;
  final int subjectId;
  final int? scheduleId;
  final DateTime date;
  final bool present;
  final DateTime markedAt;
  final String? note;

  const AttendanceRecord({
    required this.id,
    required this.subjectId,
    this.scheduleId,
    required this.date,
    required this.present,
    required this.markedAt,
    this.note,
  });

  AttendanceRecord copyWith({
    int? id,
    int? subjectId,
    int? scheduleId,
    DateTime? date,
    bool? present,
    DateTime? markedAt,
    String? note,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      scheduleId: scheduleId ?? this.scheduleId,
      date: date ?? this.date,
      present: present ?? this.present,
      markedAt: markedAt ?? this.markedAt,
      note: note ?? this.note,
    );
  }
}