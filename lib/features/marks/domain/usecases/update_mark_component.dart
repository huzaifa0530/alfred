import '../entities/mark_component.dart';
import '../repositories/marks_repository.dart';

class UpdateMarkComponent {
  final MarksRepository repository;

  UpdateMarkComponent(this.repository);

  Future<bool> call(MarkComponent component) {
    return repository.updateMarkComponent(component);
  }
}