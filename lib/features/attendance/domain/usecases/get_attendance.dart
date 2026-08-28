import '../entities/attendance_record.dart';

import '../repositories/attendance_repository.dart';

class GetAttendance {
  final AttendanceRepository repository;

  GetAttendance(this.repository);

  Stream<List<AttendanceRecord>> call(int subjectId) {
    return repository.watchAttendanceForSubject(subjectId);
  }
}