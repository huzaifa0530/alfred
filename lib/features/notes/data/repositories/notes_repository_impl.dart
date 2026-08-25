import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';
import '../datasources/notes_local_datasource.dart';

class NotesRepositoryImpl
    implements NotesRepository {
  final NotesLocalDataSource _localDataSource;

  NotesRepositoryImpl(this._localDataSource);

  @override
  Stream<List<Note>> watchNotesForSubject(
    int subjectId,
  ) {
    return _localDataSource
        .watchNotesForSubject(subjectId);
  }

  @override
  Future<List<Note>> getNotesForSubject(
    int subjectId,
  ) {
    return _localDataSource
        .getNotesForSubject(subjectId);
  }

  @override
  Future<Note?> getNote(int id) {
    return _localDataSource.getNote(id);
  }

  @override
  Future<int> createNote(Note note) {
    return _localDataSource.insertNote(note);
  }

  @override
  Future<bool> updateNote(Note note) {
    return _localDataSource.updateNote(note);
  }

  @override
  Future<void> deleteNote(int id) async {
    await _localDataSource.deleteNote(id);
  }
}