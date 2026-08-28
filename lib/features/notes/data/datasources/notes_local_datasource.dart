import '../../../../core/database/daos/notes_dao.dart';
import '../../domain/entities/note.dart';
import '../mappers/note_mapper.dart';

class NotesLocalDataSource {
  final NotesDao _dao;

  NotesLocalDataSource(this._dao);

  Stream<List<Note>> watchNotesForSubject(
    int subjectId,
  ) {
    return _dao
        .watchNotesForSubject(subjectId)
        .map(
          (items) => items
              .map<Note>(NoteMapper.fromDatabase)
              .toList(),
        );
  }

  Future<List<Note>> getNotesForSubject(
    int subjectId,
  ) async {
    final items = await _dao.getNotesForSubject(subjectId);

    return items
        .map<Note>(NoteMapper.fromDatabase)
        .toList();
  }

  Future<Note?> getNote(int id) async {
    final item = await _dao.getNoteById(id);

    if (item == null) {
      return null;
    }

    return NoteMapper.fromDatabase(item);
  }

  Future<int> insertNote(Note note) {
    return _dao.insertNote(
      NoteMapper.toInsertCompanion(note),
    );
  }

  Future<bool> updateNote(Note note) {
    return _dao.updateNote(
      NoteMapper.toUpdateCompanion(note),
    );
  }

  Future<int> deleteNote(int id) {
    return _dao.deleteNote(id);
  }

  Future<int> deleteAllNotes(int subjectId) {
    return _dao.deleteAllNotes(subjectId);
  }
}
