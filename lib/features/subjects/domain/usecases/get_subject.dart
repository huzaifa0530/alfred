import '../entities/subject.dart';
import '../repositories/subjects_repository.dart';

class GetSubject {
  final SubjectsRepository _repository;

  GetSubject(this._repository);

  Future<Subject?> call(int id) {
    return _repository.getSubject(id);
  }
}