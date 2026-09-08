import 'package:drift/drift.dart';

class AttendanceRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId => integer()();
  IntColumn get scheduleId => integer().nullable()(); // keep nullable

  DateTimeColumn get date => dateTime()();

  // OLD: BoolColumn get present => boolean().withDefault(const Constant(true))();
  // NEW:
  TextColumn get status => text()(); 
  // For backwards compat, keep present getter as helper in entity, not in table
  // Or migrate: present = status == present

  TextColumn get note => text().nullable()();
  
  DateTimeColumn get markedAt => dateTime().withDefault(currentDateAndTime)();
}