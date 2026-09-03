// domain/usecases/create_attendance.dart
import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class CreateAttendance {
  final AttendanceRepository repository;

  CreateAttendance(this.repository);

  Future<int> call(AttendanceRecord record) async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final recordDateOnly = DateTime(record.date.year, record.date.month, record.date.day);

    if (recordDateOnly.isAfter(todayOnly)) {
      throw ArgumentError(
        'Cannot mark attendance for a future date: ${record.date}',
      );
    }

    final existing = record.scheduleId != null
        ? await repository.getAttendanceForSchedule(
            scheduleId: record.scheduleId!,
            date: record.date,
          )
        : await repository.getBySubjectAndDate(
            record.subjectId,
            record.date,
          );

    if (existing != null) {
      final updated = existing.copyWith(
        present: record.present,
        markedAt: record.markedAt,
        note: record.note,
      );

      await repository.updateAttendance(updated);

      return existing.id;
    }

    return repository.markAttendance(record);
  }
}