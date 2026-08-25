import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/note.dart';
import '../models/note_model.dart';

class NoteMapper {
  const NoteMapper._();

  static NoteModel fromDatabase(db.Note data) {
    return NoteModel(
      id: data.id,
      subjectId: data.subjectId,
      content: data.content,
      noteType: data.noteType,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  static db.NotesCompanion toInsertCompanion(
    Note note,
  ) {
    return db.NotesCompanion.insert(
      subjectId: note.subjectId,
      content: note.content,
      noteType: Value(note.noteType),
    );
  }

  static db.NotesCompanion toUpdateCompanion(
    Note note,
  ) {
    return db.NotesCompanion(
      id: Value(note.id),
      subjectId: Value(note.subjectId),
      content: Value(note.content),
      noteType: Value(note.noteType),
      createdAt: Value(note.createdAt),
      updatedAt: Value(note.updatedAt),
    );
  }
}