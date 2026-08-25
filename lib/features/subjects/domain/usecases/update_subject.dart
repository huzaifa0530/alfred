import '../entities/subject.dart';
import '../repositories/subjects_repository.dart';

class UpdateSubject {
  final SubjectsRepository _repository;

  UpdateSubject(this._repository);

  Future<bool> call(Subject subject) {
    return _repository.updateSubject(subject);
  }
}