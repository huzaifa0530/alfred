import 'package:drift/drift.dart';

class Events extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get subjectId =>
      integer().nullable()();

  TextColumn get title =>
      text()();

  TextColumn get description =>
      text().nullable()();

  TextColumn get type =>
      text()();

  TextColumn get priority =>
      text().withDefault(
        const Constant('normal'),
      )();

  DateTimeColumn get dueDate =>
      dateTime()();

  BoolColumn get isCompleted =>
      boolean().withDefault(
        const Constant(false),
      )();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(
        currentDateAndTime,
      )();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(
        currentDateAndTime,
      )();
}