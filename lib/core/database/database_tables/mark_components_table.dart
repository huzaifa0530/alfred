import 'package:drift/drift.dart';

class MarkComponents extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Subject this assessment belongs to.
  IntColumn get subjectId => integer()();

  /// Example: Quiz 1, Quiz 2, Midterm, Final, Project.
  TextColumn get name => text()();

  /// Optional category/type.
  /// Example: quiz, assignment, midterm, final, project, performance.
  TextColumn get type => text().nullable()();

  /// Maximum marks for this assessment.
  /// Example: 5, 10, 20, 40.
  RealColumn get maxMarks => real()();

  /// Controls the order in which components appear.
  IntColumn get sortOrder =>
      integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}