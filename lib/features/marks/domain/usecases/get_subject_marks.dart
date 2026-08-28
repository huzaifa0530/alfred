import '../entities/mark.dart';
import '../repositories/marks_repository.dart';

class GetSubjectMarks {
  final MarksRepository repository;

  GetSubjectMarks(this.repository);

  Stream<List<Mark>> call(int subjectId) {
    return repository.watchMarksForSubject(subjectId);
  }
}