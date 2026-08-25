import '../entities/subject.dart';
import '../repositories/subjects_repository.dart';

class CreateSubject {
  final SubjectsRepository _repository;

  CreateSubject(this._repository);

  Future<int> call(Subject subject) {
    return _repository.createSubject(subject);
  }
}