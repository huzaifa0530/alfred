import 'package:drift/drift.dart';

class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(
        min: 1,
        max: 150,
      )();

  TextColumn get code => text().nullable()();

  TextColumn get instructor => text().nullable()();

  TextColumn get room => text().nullable()();

  TextColumn get color => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(
        const Constant(true),
      )();

  DateTimeColumn get createdAt => dateTime().withDefault(
        currentDateAndTime,
      )();

  DateTimeColumn get updatedAt => dateTime().withDefault(
        currentDateAndTime,
      )();
}