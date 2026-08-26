import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as database;
import '../../domain/entities/event.dart';

class EventMapper {
  const EventMapper._();

  static Event fromDatabase(
    database.Event data,
  ) {
    return Event(
      id: data.id,
      subjectId: data.subjectId,
      title: data.title,
      description: data.description,
      type: data.type,
      priority: data.priority,
      dueDate: data.dueDate,
      isCompleted: data.isCompleted,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  static database.EventsCompanion toCompanion(
    Event event,
  ) {
    return database.EventsCompanion.insert(
      subjectId: Value(event.subjectId),
      title: event.title,
      description:
          Value(event.description),
      type: event.type,
      priority: Value(event.priority),
      dueDate: event.dueDate,
      isCompleted:
          Value(event.isCompleted),
      createdAt:
          Value(event.createdAt),
      updatedAt:
          Value(event.updatedAt),
    );
  }
}