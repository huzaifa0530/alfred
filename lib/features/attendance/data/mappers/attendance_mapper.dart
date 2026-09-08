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
      status: _parseStatus(status), // <-- was present: present
      markedAt: markedAt,
      note: note,
    );
  }
}

extension AttendanceRecordCompanionMapper on AttendanceRecord {
  db.AttendanceRecordsCompanion toInsertCompanion() {
    return db.AttendanceRecordsCompanion.insert(
      subjectId: subjectId,
      scheduleId: Value(scheduleId),
      date: date,
      status: status.name, // <-- was present
      markedAt: Value(markedAt),
      note: Value(note),
    );
  }

  db.AttendanceRecordsCompanion toUpdateCompanion() {
    return db.AttendanceRecordsCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      scheduleId: Value(scheduleId),
      date: Value(date),
      status: Value(status.name), // <-- was present
      markedAt: Value(markedAt),
      note: Value(note),
    );
  }
}

AttendanceStatus _parseStatus(String raw) {
  return AttendanceStatus.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => AttendanceStatus.present,
  );
}