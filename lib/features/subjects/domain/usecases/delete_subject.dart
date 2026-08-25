import '../repositories/subjects_repository.dart';

class DeleteSubject {
  final SubjectsRepository _repository;

  DeleteSubject(this._repository);

  Future<void> call(int id) {
    return _repository.deleteSubject(id);
  }
}