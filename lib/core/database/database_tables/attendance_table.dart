import 'package:drift/drift.dart';

class AttendanceRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get subjectId => integer()();
//i add a scehdule id recently i think need change dao and al feature
  IntColumn get scheduleId => integer().nullable()();

  DateTimeColumn get date => dateTime()();

  BoolColumn get present =>
      boolean().withDefault(const Constant(true))();

  DateTimeColumn get markedAt =>
      dateTime().withDefault(currentDateAndTime)();

  TextColumn get note =>
      text().nullable()();
}