import 'package:drift/drift.dart';

class Marks extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Subject this mark belongs to.
  IntColumn get subjectId => integer()();

  /// Assessment component.
  /// Example: Quiz 1, Midterm, Final.
  IntColumn get componentId => integer()();

  /// Actual marks obtained by the student.
  ///
  /// Nullable means the mark has not been entered yet.
  /// NULL is different from 0.
  RealColumn get obtainedMarks => real().nullable()();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}