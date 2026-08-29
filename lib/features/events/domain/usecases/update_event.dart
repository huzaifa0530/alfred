import '../entities/event.dart';
import '../repositories/events_repository.dart';

class UpdateEvent {
  final EventsRepository repository;
  UpdateEvent(this.repository);
  Future<void> call(Event event) => repository.updateEvent(event);
}