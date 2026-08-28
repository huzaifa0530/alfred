class Mark {
  final int id;
  final int subjectId;
  final int componentId;
  final double? obtainedMarks;
  final DateTime updatedAt;

  const Mark({
    required this.id,
    required this.subjectId,
    required this.componentId,
    this.obtainedMarks,
    required this.updatedAt,
  });

  Mark copyWith({
    int? id,
    int? subjectId,
    int? componentId,
    double? obtainedMarks,
    DateTime? updatedAt,
  }) {
    return Mark(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      componentId: componentId ?? this.componentId,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}