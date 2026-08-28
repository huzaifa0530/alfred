import 'package:alfred/core/database/database_tables/notes_table.dart';
import 'package:drift/drift.dart';

import '../app_database.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase>
    with _$NotesDaoMixin {
  NotesDao(super.db);

  Stream<List<Note>> watchNotesForSubject(
    int subjectId,
  ) {
    return (select(attachedDatabase.notes)
          ..where(
            (note) => note.subjectId.equals(subjectId),
          )
          ..orderBy([
            (note) => OrderingTerm(
                  expression: note.createdAt,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  Future<List<Note>> getNotesForSubject(
    int subjectId,
  ) {
    return (select(attachedDatabase.notes)
          ..where(
            (note) => note.subjectId.equals(subjectId),
          )
          ..orderBy([
            (note) => OrderingTerm(
                  expression: note.createdAt,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();
  }

  Future<Note?> getNoteById(int id) {
    return (select(attachedDatabase.notes)
          ..where(
            (note) => note.id.equals(id),
          ))
        .getSingleOrNull();
  }

  Future<int> insertNote(
    NotesCompanion entry,
  ) {
    return into(attachedDatabase.notes).insert(entry);
  }

  Future<bool> updateNote(
    NotesCompanion entry,
  ) {
    return update(attachedDatabase.notes).replace(entry);
  }

  Future<int> deleteNote(int id) {
    return (delete(attachedDatabase.notes)
          ..where(
            (note) => note.id.equals(id),
          ))
        .go();
  }

  Future<int> deleteAllNotes(int subjectId) {
    return (delete(attachedDatabase.notes)
          ..where(
            (note) => note.subjectId.equals(subjectId),
          ))
        .go();
  }
}
