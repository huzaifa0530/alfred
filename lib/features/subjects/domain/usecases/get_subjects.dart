import '../entities/subject.dart';
import '../repositories/subjects_repository.dart';

class GetSubjects {
  final SubjectsRepository _repository;

  GetSubjects(this._repository);

  Stream<List<Subject>> call() {
    return _repository.watchSubjects();
  }
}

