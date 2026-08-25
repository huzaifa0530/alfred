import '../entities/note.dart';

abstract interface class NotesRepository {
  Stream<List<Note>> watchNotesForSubject(
    int subjectId,
  );

  Future<List<Note>> getNotesForSubject(
    int subjectId,
  );

  Future<Note?> getNote(int id);

  Future<int> createNote(Note note);

  Future<bool> updateNote(Note note);

  Future<void> deleteNote(int id);
}