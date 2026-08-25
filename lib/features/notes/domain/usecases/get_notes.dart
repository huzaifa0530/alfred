import '../entities/note.dart';
import '../repositories/notes_repository.dart';

class GetNotes {
  final NotesRepository _repository;

  GetNotes(this._repository);

  Stream<List<Note>> call(int subjectId) {
    return _repository.watchNotesForSubject(
      subjectId,
    );
  }
}