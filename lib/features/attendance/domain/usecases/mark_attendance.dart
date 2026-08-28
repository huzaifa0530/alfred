import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class MarkAttendance {
  final AttendanceRepository repository;

  MarkAttendance(this.repository);

  Future<int> call(AttendanceRecord attendance) {
    return repository.markAttendance(attendance);
  }
}