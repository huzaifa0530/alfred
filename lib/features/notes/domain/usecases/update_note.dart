import 'package:alfred/features/notes/domain/entities/note.dart';
import 'package:alfred/features/notes/domain/repositories/notes_repository.dart';

class UpdateNote {
  final NotesRepository _repository;

  UpdateNote(this._repository);

  Future<bool> call(Note note) {
    return _repository.updateNote(note);
  }
}