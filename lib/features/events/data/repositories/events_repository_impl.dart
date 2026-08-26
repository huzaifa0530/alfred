import '../../domain/entities/event.dart';
import '../../domain/repositories/events_repository.dart';
import '../datasources/events_local_datasource.dart';

class EventsRepositoryImpl
    implements EventsRepository {
  final EventsLocalDataSource _localDataSource;

  EventsRepositoryImpl(
    this._localDataSource,
  );

  @override
  Stream<List<Event>> watchAllEvents() {
    return _localDataSource.watchAllEvents();
  }

  @override
  Stream<List<Event>> watchUpcomingEvents() {
    return _localDataSource
        .watchUpcomingEvents();
  }

  @override
  Stream<List<Event>>
      watchEventsForSubject(
    int subjectId,
  ) {
    return _localDataSource
        .watchEventsForSubject(subjectId);
  }

  @override
  Future<Event?> getEvent(int id) {
    return _localDataSource.getEvent(id);
  }

  @override
  Future<int> createEvent(Event event) {
    return _localDataSource
        .createEvent(event);
  }

  @override
  Future<void> updateEvent(Event event) {
    return _localDataSource
        .updateEvent(event);
  }

  @override
  Future<void> deleteEvent(int id) {
    return _localDataSource
        .deleteEvent(id);
  }

  @override
  Future<void> markCompleted(
    int id,
    bool completed,
  ) {
    return _localDataSource
        .markCompleted(
      id,
      completed,
    );
  }
}