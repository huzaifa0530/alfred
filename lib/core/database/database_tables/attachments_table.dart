import 'package:drift/drift.dart';

class Attachments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get noteId => integer()();

  TextColumn get type =>
      text()();

  TextColumn get name =>
      text()();

  TextColumn get path =>
      text()();

  TextColumn get mimeType =>
      text().nullable()();

  IntColumn get sizeBytes =>
      integer().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}