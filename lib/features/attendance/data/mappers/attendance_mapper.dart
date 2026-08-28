import 'package:drift/drift.dart';
import 'package:alfred/core/database/app_database.dart' as db;

import '../../domain/entities/attendance_record.dart';

extension AttendanceRecordMapper on db.AttendanceRecord {
  AttendanceRecord toEntity() {
    return AttendanceRecord(
      id: id,
      subjectId: subjectId,
      scheduleId: scheduleId,
      date: date,
      present: present,
      markedAt: markedAt,
      note: note,
    );
  }
}

extension AttendanceRecordCompanionMapper on AttendanceRecord {
  /// For inserting a brand-new record (id not known yet).
  db.AttendanceRecordsCompanion toInsertCompanion() {
    return db.AttendanceRecordsCompanion.insert(
      subjectId: subjectId,
      scheduleId: Value(scheduleId),
      date: date,
      present: Value(present),
      markedAt: Value(markedAt),
      note: Value(note),
    );
  }

  /// For updating an existing record (id required).
  db.AttendanceRecordsCompanion toUpdateCompanion() {
    return db.AttendanceRecordsCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      scheduleId: Value(scheduleId),
      date: Value(date),
      present: Value(present),
      markedAt: Value(markedAt),
      note: Value(note),
    );
  }
}