import 'package:alfred/core/database/daos/attendance_dao.dart';
import 'package:alfred/features/attendance/data/mappers/attendance_mapper.dart';

import '../../domain/entities/attendance_record.dart';

class AttendanceLocalDataSource {
  final AttendanceDao dao;

  AttendanceLocalDataSource(this.dao);

  Stream<List<AttendanceRecord>> watchAllAttendance() {
    return dao.watchAllAttendance().map(
      (records) => records.map((r) => r.toEntity()).toList(),
    );
  }

  Stream<List<AttendanceRecord>> watchAttendanceForSubject(int subjectId) {
    return dao.watchAttendanceForSubject(subjectId).map(
      (records) => records.map((r) => r.toEntity()).toList(),
    );
  }

  Future<AttendanceRecord?> getAttendanceForDate({
    required int subjectId,
    required DateTime date,
  }) async {
    final record = await dao.getBySubjectAndDate(subjectId, date);
    return record?.toEntity();
  }

  Future<AttendanceRecord?> getAttendanceForSchedule({
    required int scheduleId,
    required DateTime date,
  }) async {
    final record = await dao.getByScheduleAndDate(scheduleId, date);
    return record?.toEntity();
  }

  Future<int> markAttendance(AttendanceRecord attendance) {
    return dao.insertAttendance(attendance.toInsertCompanion());
  }

  Future<void> updateAttendance(AttendanceRecord attendance) {
    return dao.updateAttendance(attendance.id, attendance.toUpdateCompanion());
  }

  Future<void> deleteAttendance(int id) {
    return dao.deleteAttendance(id);
  }
}