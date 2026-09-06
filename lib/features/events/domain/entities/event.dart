class _Unset {
  const _Unset();
}

const _unset = _Unset();

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
    Object? subjectId = _unset,
    String? title,
    Object? description = _unset,
    String? type,
    String? priority,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      subjectId: identical(subjectId, _unset)
          ? this.subjectId
          : subjectId as int?,
      title: title ?? this.title,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}