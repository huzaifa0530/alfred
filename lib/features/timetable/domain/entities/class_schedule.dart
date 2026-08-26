class ClassSchedule {
  final int id;
  final int subjectId;
  final int weekday;
  final String startTime;
  final String endTime;
  final String? room;
  final String? teacher;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassSchedule({
    required this.id,
    required this.subjectId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.room,
    this.teacher,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get weekdayName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[weekday - 1];
  }

  ClassSchedule copyWith({
    int? id,
    int? subjectId,
    int? weekday,
    String? startTime,
    String? endTime,
    String? room,
    String? teacher,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassSchedule(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      weekday: weekday ?? this.weekday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      teacher: teacher ?? this.teacher,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}