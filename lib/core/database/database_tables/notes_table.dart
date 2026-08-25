import 'package:drift/drift.dart';

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get subjectId => integer()();

  TextColumn get content => text()();

  TextColumn get noteType =>
      text().withDefault(const Constant('text'))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}