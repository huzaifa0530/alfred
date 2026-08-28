import '../entities/mark.dart';
import '../repositories/marks_repository.dart';

class SaveMark {
  final MarksRepository repository;

  SaveMark(this.repository);

  Future<void> call(Mark mark) {
    return repository.saveMark(mark);
  }
}