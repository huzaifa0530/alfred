import '../entities/mark.dart';
import '../repositories/marks_repository.dart';

class CreateMark {
  final MarksRepository repository;

  CreateMark(this.repository);

  Future<int> call(Mark mark) {
    return repository.createMark(mark);
  }
}