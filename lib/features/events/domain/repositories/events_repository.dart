import '../entities/event.dart';

abstract interface class EventsRepository {
  Stream<List<Event>> watchAllEvents();

  Stream<List<Event>> watchUpcomingEvents();

  Stream<List<Event>> watchEventsForSubject(
    int subjectId,
  );

  Future<Event?> getEvent(int id);

  Future<int> createEvent(Event event);

  Future<void> updateEvent(Event event);

  Future<void> deleteEvent(int id);

  Future<void> markCompleted(
    int id,
    bool completed,
  );
}