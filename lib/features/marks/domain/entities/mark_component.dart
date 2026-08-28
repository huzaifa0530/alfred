class MarkComponent {
  final int id;
  final int subjectId;

  /// Display name.
  /// Examples:
  /// Quiz 1
  /// Quiz 2
  /// Assignment 1
  /// Midterm
  /// Final
  /// Project
  /// Performance
  final String name;

  /// Optional category.
  /// Examples:
  /// quiz
  /// assignment
  /// midterm
  /// final
  /// project
  /// performance
  final String? type;

  /// Maximum marks for this component.
  final double maxMarks;

  /// Controls the order on the marks screen.
  final int sortOrder;

  final DateTime createdAt;

  const MarkComponent({
    required this.id,
    required this.subjectId,
    required this.name,
    this.type,
    required this.maxMarks,
    required this.sortOrder,
    required this.createdAt,
  });

  MarkComponent copyWith({
    int? id,
    int? subjectId,
    String? name,
    String? type,
    double? maxMarks,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return MarkComponent(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      type: type ?? this.type,
      maxMarks: maxMarks ?? this.maxMarks,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}