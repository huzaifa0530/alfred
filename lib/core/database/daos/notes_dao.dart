import 'package:alfred/core/database/database_tables/notes_table.dart';
import 'package:drift/drift.dart';

import '../app_database.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  Stream<List<Note>> watchNotesForSubject(int subjectId) {
    return (select(attachedDatabase.notes)
          ..where((note) => note.subjectId.equals(subjectId))
          ..orderBy([
            (note) => OrderingTerm(
              expression: note.createdAt,
              mode: OrderingMode.asc,
            ),
          ]))
        .watch();
  }

  Future<List<Note>> getNotesForSubject(int subjectId) {
    return (select(attachedDatabase.notes)
          ..where((note) => note.subjectId.equals(subjectId))
          ..orderBy([
            (note) => OrderingTerm(
              expression: note.createdAt,
              mode: OrderingMode.asc,
            ),
          ]))
        .get();
  }

  Future<Note?> getNoteById(int id) {
    return (select(
      attachedDatabase.notes,
    )..where((note) => note.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertNote(NotesCompanion entry) {
    return into(attachedDatabase.notes).insert(entry);
  }

  Future<int> updateNote(NotesCompanion entry) {
    return (update(
      attachedDatabase.notes,
    )..where((note) => note.id.equals(entry.id.value))).write(entry);
  }

  Future<int> deleteNote(int id) {
    return (delete(
      attachedDatabase.notes,
    )..where((note) => note.id.equals(id))).go();
  }

  Future<int> deleteAllNotes(int subjectId) {
    return (delete(
      attachedDatabase.notes,
    )..where((note) => note.subjectId.equals(subjectId))).go();
  }

  Future<void> moveNoteToSubject(int noteId, int newSubjectId) async {
    await (update(notes)..where((tbl) => tbl.id.equals(noteId))).write(
      NotesCompanion(
        subjectId: Value(newSubjectId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
