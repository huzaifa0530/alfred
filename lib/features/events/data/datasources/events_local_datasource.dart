import '../../../../core/database/daos/events_dao.dart';
import '../../domain/entities/event.dart';
import '../mappers/event_mapper.dart';

class EventsLocalDataSource {
  final EventsDao _dao;

  EventsLocalDataSource(this._dao);

  Stream<List<Event>> watchAllEvents() {
    return _dao
        .watchAllEvents()
        .map(
          (items) => items
              .map(
                EventMapper.fromDatabase,
              )
              .toList(),
        );
  }

  Stream<List<Event>>
      watchUpcomingEvents() {
    return _dao
        .watchUpcomingEvents()
        .map(
          (items) => items
              .map(
                EventMapper.fromDatabase,
              )
              .toList(),
        );
  }

  Stream<List<Event>>
      watchEventsForSubject(
    int subjectId,
  ) {
    return _dao
        .watchEventsForSubject(subjectId)
        .map(
          (items) => items
              .map(
                EventMapper.fromDatabase,
              )
              .toList(),
        );
  }

  Future<Event?> getEvent(int id) async {
    final data =
        await _dao.getEventById(id);

    if (data == null) {
      return null;
    }

    return EventMapper.fromDatabase(data);
  }

  Future<int> createEvent(Event event) {
  return _dao.insertEvent(
    EventMapper.toInsertCompanion(event), // was toCompanion
  );
}

Future<void> updateEvent(Event event) async {
  await _dao.updateEvent(
    EventMapper.toUpdateCompanion(event), // was toCompanion
  );
}

  Future<void> deleteEvent(int id) async {
    await _dao.deleteEvent(id);
  }

  Future<void> markCompleted(
    int id,
    bool completed,
  ) async {
    await _dao.markCompleted(
      id,
      completed,
    );
  }
}