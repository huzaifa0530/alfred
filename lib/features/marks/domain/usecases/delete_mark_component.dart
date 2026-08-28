import '../repositories/marks_repository.dart';

class DeleteMarkComponent {
  final MarksRepository repository;

  DeleteMarkComponent(this.repository);

  Future<void> call(int id) {
    return repository.deleteMarkComponent(id);
  }
}