import '../entities/attendance_record.dart';

abstract class AttendanceRepository {
  Stream<List<AttendanceRecord>> watchAllAttendance();

  Stream<List<AttendanceRecord>> watchAttendanceForSubject(
    int subjectId,
  );

  Future<AttendanceRecord?> getAttendanceForDate({
    required int subjectId,
    required DateTime date,
  });

  Future<AttendanceRecord?> getAttendanceForSchedule({
    required int scheduleId,
    required DateTime date,
  });

  Future<int> markAttendance(
    AttendanceRecord attendance,
  );

  Future<void> updateAttendance(
    AttendanceRecord attendance,
  );

  Future<void> deleteAttendance(int id);

  Future<AttendanceRecord?> getBySubjectAndDate(
    int subjectId,
    DateTime date,
  );
}