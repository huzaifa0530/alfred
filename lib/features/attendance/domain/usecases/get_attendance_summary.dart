import '../repositories/attendance_repository.dart';

class AttendanceSummary {
  final int total;
  final int present;
  final int absent;
  final double percentage;

  const AttendanceSummary({
    required this.total,
    required this.present,
    required this.absent,
    required this.percentage,
  });
}

class GetAttendanceSummary {
  final AttendanceRepository repository;

  GetAttendanceSummary(this.repository);

  Future<AttendanceSummary> call(int subjectId) async {
    final records = await repository.watchAttendanceForSubject(subjectId).first;

    final total = records.length;
    final present = records.where((record) => record.present).length;
    final absent = total - present;

    final percentage = total == 0
        ? 0.0
        : (present / total) * 100;

    return AttendanceSummary(
      total: total,
      present: present,
      absent: absent,
      percentage: percentage,
    );
  }
}