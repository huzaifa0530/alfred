import '../../domain/entities/note.dart';

class NoteModel extends Note {
  const NoteModel({
    required super.id,
    required super.subjectId,
    required super.content,
    required super.noteType,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NoteModel.fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      subjectId: note.subjectId,
      content: note.content,
      noteType: note.noteType,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    );
  }

  Note toEntity() {
    return Note(
      id: id,
      subjectId: subjectId,
      content: content,
      noteType: noteType,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}