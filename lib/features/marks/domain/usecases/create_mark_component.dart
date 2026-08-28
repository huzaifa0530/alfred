import '../entities/mark_component.dart';
import '../repositories/marks_repository.dart';

class CreateMarkComponent {
  final MarksRepository repository;

  CreateMarkComponent(this.repository);

  Future<int> call(MarkComponent component) {
    return repository.createMarkComponent(component);
  }
}