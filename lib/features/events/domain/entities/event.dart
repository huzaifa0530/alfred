class Event {
  final int id;
  final int? subjectId;
  final String title;
  final String? description;
  final String type;
  final String priority;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    this.subjectId,
    required this.title,
    this.description,
    required this.type,
    required this.priority,
    required this.dueDate,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOverdue {
    return !isCompleted &&
        dueDate.isBefore(DateTime.now());
  }

  bool get isCompletedEvent {
    return isCompleted;
  }

  bool get isUpcoming {
    return !isCompleted &&
        dueDate.isAfter(DateTime.now());
  }

  Event copyWith({
    int? id,
    int? subjectId,
    String? title,
    String? description,
    String? type,
    String? priority,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description:
          description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted:
          isCompleted ?? this.isCompleted,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }
}