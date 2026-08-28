import 'package:alfred/features/attendance/domain/repositories/attendance_repository.dart';

import '../entities/attendance_record.dart';

class GetAttendanceForSchedule {
  final AttendanceRepository repository;

  GetAttendanceForSchedule(this.repository);

  Future<AttendanceRecord?> call({
    required int scheduleId,
    required DateTime date,
  }) {
    return repository.getAttendanceForSchedule(
      scheduleId: scheduleId,
      date: date,
    );
  }
}