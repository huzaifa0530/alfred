import 'package:drift/drift.dart';

class ClassSchedules extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get subjectId =>
      integer()();

  /// 1 = Monday
  /// 2 = Tuesday
  /// ...
  /// 7 = Sunday
  IntColumn get weekday =>
      integer()();

  TextColumn get startTime =>
      text()();

  TextColumn get endTime =>
      text()();

  TextColumn get room =>
      text().nullable()();

  TextColumn get teacher =>
      text().nullable()();

  TextColumn get notes =>
      text().nullable()();

  BoolColumn get isActive =>
      boolean().withDefault(
        const Constant(true),
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