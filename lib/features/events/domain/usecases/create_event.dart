import '../entities/event.dart';
import '../repositories/events_repository.dart';

class CreateEvent {
  final EventsRepository repository;
  CreateEvent(this.repository);
  Future<int> call(Event event) => repository.createEvent(event);
}