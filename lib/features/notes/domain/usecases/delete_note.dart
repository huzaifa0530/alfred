import '../entities/note.dart';
import '../repositories/notes_repository.dart';

class DeleteNote {
  final NotesRepository _repository;

  DeleteNote(this._repository);

  Future<void> call(int id) {
    return _repository.deleteNote(id);
  }
}