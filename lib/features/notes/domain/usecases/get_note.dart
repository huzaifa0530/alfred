import '../entities/note.dart';
import '../repositories/notes_repository.dart';

class GetNote {
  final NotesRepository _repository;

  GetNote(this._repository);

  Future<Note?> call(int id) {
    return _repository.getNote(id);
  }
}