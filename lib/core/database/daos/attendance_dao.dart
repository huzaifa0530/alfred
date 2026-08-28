import 'package:alfred/core/database/database_tables/attendance_table.dart';
import 'package:drift/drift.dart';

import '../app_database.dart';

part 'attendance_dao.g.dart';

@DriftAccessor(tables: [AttendanceRecords])
class AttendanceDao extends DatabaseAccessor<AppDatabase>
    with _$AttendanceDaoMixin {
  AttendanceDao(super.db);

  // WATCH ALL
  Stream<List<AttendanceRecord>> watchAllAttendance() {
    return select(attendanceRecords).watch();
  }

  // WATCH BY SUBJECT
  Stream<List<AttendanceRecord>> watchAttendanceForSubject(
    int subjectId,
  ) {
    return (select(attendanceRecords)
          ..where((tbl) => tbl.subjectId.equals(subjectId))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.date,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  // INSERT
  Future<int> insertAttendance(
    AttendanceRecordsCompanion entry,
  ) {
    return into(attendanceRecords).insert(entry);
  }

  // UPDATE
  Future<bool> updateAttendance(
    int id,
    AttendanceRecordsCompanion entry,
  ) async {
    final count = await (update(attendanceRecords)
          ..where((tbl) => tbl.id.equals(id)))
        .write(entry);

    return count > 0;
  }

  // DELETE
  Future<void> deleteAttendance(int id) async {
    await (delete(attendanceRecords)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }
  // GET BY SCHEDULE + DATE  (used for duplicate prevention)
  Future<AttendanceRecord?> getByScheduleAndDate(
    int scheduleId,
    DateTime date,
  ) {
    return (select(attendanceRecords)
          ..where(
            (tbl) =>
                tbl.scheduleId.equals(scheduleId) &
                tbl.date.equals(date),
          ))
        .getSingleOrNull();
  }
  // GET BY SUBJECT + DATE
  Future<AttendanceRecord?> getBySubjectAndDate(
    int subjectId,
    DateTime date,
  ) {
    return (select(attendanceRecords)
          ..where(
            (tbl) =>
                tbl.subjectId.equals(subjectId) &
                tbl.date.equals(date),
          ))
        .getSingleOrNull();
  }
}