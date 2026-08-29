import '../repositories/events_repository.dart';

class MarkEventCompleted {
  final EventsRepository repository;
  MarkEventCompleted(this.repository);
  Future<void> call(int id, bool completed) => repository.markCompleted(id, completed);
}