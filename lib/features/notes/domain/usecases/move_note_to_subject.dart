import '../repositories/notes_repository.dart';

class MoveNoteToSubject {
  final NotesRepository _repository;

  MoveNoteToSubject(this._repository);

  Future<void> call(int noteId, int newSubjectId) {
    return _repository.moveNoteToSubject(noteId, newSubjectId);
  }
}