import '../entities/mark.dart';
import '../repositories/marks_repository.dart';

class GetMarks {
  final MarksRepository repository;

  GetMarks(this.repository);

  Stream<List<Mark>> call() {
    return repository.watchMarks();
  }
}