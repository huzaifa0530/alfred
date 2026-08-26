import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as database;
import '../../domain/entities/class_schedule.dart';

class TimetableMapper {
  const TimetableMapper._();

  static ClassSchedule fromDatabase(
    database.ClassSchedule data,
  ) {
    return ClassSchedule(
      id: data.id,
      subjectId: data.subjectId,
      weekday: data.weekday,
      startTime: data.startTime,
      endTime: data.endTime,
      room: data.room,
      teacher: data.teacher,
      notes: data.notes,
      isActive: data.isActive,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  static database.ClassSchedulesCompanion toCompanion(
    ClassSchedule schedule,
  ) {
    return database.ClassSchedulesCompanion.insert(
      subjectId: schedule.subjectId,
      weekday: schedule.weekday,
      startTime: schedule.startTime,
      endTime: schedule.endTime,
      room: Value(schedule.room),
      teacher: Value(schedule.teacher),
      notes: Value(schedule.notes),
      isActive: Value(schedule.isActive),
      createdAt: Value(schedule.createdAt),
      updatedAt: Value(schedule.updatedAt),
    );
  }
}