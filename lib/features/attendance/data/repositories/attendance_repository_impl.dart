import 'package:alfred/features/attendance/data/datasources/attendance_local_datasource.dart';
import 'package:alfred/features/attendance/domain/repositories/attendance_repository.dart';

import '../../domain/entities/attendance_record.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceLocalDataSource localDataSource;

  AttendanceRepositoryImpl(this.localDataSource);

  @override
  Stream<List<AttendanceRecord>> watchAllAttendance() {
    return localDataSource.watchAllAttendance();
  }

  @override
  Stream<List<AttendanceRecord>> watchAttendanceForSubject(int subjectId) {
    return localDataSource.watchAttendanceForSubject(subjectId);
  }

  @override
  Future<AttendanceRecord?> getAttendanceForDate({
    required int subjectId,
    required DateTime date,
  }) {
    return localDataSource.getAttendanceForDate(subjectId: subjectId, date: date);
  }

  @override
  Future<AttendanceRecord?> getAttendanceForSchedule({
    required int scheduleId,
    required DateTime date,
  }) {
    return localDataSource.getAttendanceForSchedule(scheduleId: scheduleId, date: date);
  }

  @override
  Future<int> markAttendance(AttendanceRecord attendance) {
    return localDataSource.markAttendance(attendance);
  }

  @override
  Future<void> updateAttendance(AttendanceRecord attendance) {
    return localDataSource.updateAttendance(attendance);
  }

  @override
  Future<void> deleteAttendance(int id) {
    return localDataSource.deleteAttendance(id);
  }

  @override
  Future<AttendanceRecord?> getBySubjectAndDate(int subjectId, DateTime date) {
    return localDataSource.getAttendanceForDate(subjectId: subjectId, date: date);
  }
}