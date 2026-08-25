
import 'package:alfred/features/notes/domain/entities/note.dart';
import 'package:alfred/features/notes/domain/repositories/notes_repository.dart';

class CreateNote {
  final NotesRepository _repository;

  CreateNote(this._repository);

  Future<int> call(Note subject) {
    return _repository.createNote(subject);
  }
}