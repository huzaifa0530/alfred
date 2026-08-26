import 'package:alfred/core/database/database_tables/events_table.dart';
import 'package:drift/drift.dart';

import '../app_database.dart';

part 'events_dao.g.dart';

@DriftAccessor(tables: [Events])
class EventsDao extends DatabaseAccessor<AppDatabase>
    with _$EventsDaoMixin {
  EventsDao(super.db);

  Stream<List<Event>> watchAllEvents() {
    return (select(events)
          ..orderBy([
            (event) => OrderingTerm(
                  expression: event.dueDate,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  Stream<List<Event>>
      watchUpcomingEvents() {
    return (select(events)
          ..where(
            (event) =>
                event.isCompleted.equals(false),
          )
          ..orderBy([
            (event) => OrderingTerm(
                  expression: event.dueDate,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  Stream<List<Event>>
      watchEventsForSubject(
    int subjectId,
  ) {
    return (select(events)
          ..where(
            (event) =>
                event.subjectId.equals(subjectId),
          )
          ..orderBy([
            (event) => OrderingTerm(
                  expression: event.dueDate,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  Future<Event?> getEventById(
    int id,
  ) {
    return (select(events)
          ..where(
            (event) => event.id.equals(id),
          ))
        .getSingleOrNull();
  }

  Future<int> insertEvent(
    EventsCompanion event,
  ) {
    return into(events).insert(event);
  }

  Future<bool> updateEvent(
    EventsCompanion event,
  ) {
    return update(events).replace(
      event,
    );
  }

  Future<int> deleteEvent(int id) {
    return (delete(events)
          ..where(
            (event) => event.id.equals(id),
          ))
        .go();
  }

  Future<int> markCompleted(
    int id,
    bool completed,
  ) {
    return (update(events)
          ..where(
            (event) => event.id.equals(id),
          ))
        .write(
      EventsCompanion(
        isCompleted:
            Value(completed),
        updatedAt:
            Value(DateTime.now()),
      ),
    );
  }
}