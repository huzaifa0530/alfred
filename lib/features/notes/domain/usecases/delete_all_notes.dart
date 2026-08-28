import '../repositories/notes_repository.dart';

class DeleteAllNotes {
  final NotesRepository _repository;

  DeleteAllNotes(this._repository);

  Future<void> call(int subjectId) {
    return _repository.deleteAllNotes(subjectId);
  }
}
