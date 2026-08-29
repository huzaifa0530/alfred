import '../repositories/events_repository.dart';

class DeleteEvent {
  final EventsRepository repository;
  DeleteEvent(this.repository);
  Future<void> call(int id) => repository.deleteEvent(id);
}