class Note {
  final int id;
  final int subjectId;
  final String content;
  final String noteType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEdited;

  const Note({
    required this.id,
    required this.subjectId,
    required this.content,
    required this.noteType,
    required this.createdAt,
    required this.updatedAt,
    this.isEdited = false,
  });

  Note copyWith({
    int? id,
    int? subjectId,
    String? content,
    String? noteType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
  }) {
    return Note(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      content: content ?? this.content,
      noteType: noteType ?? this.noteType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}