import '../entities/class_schedule.dart';
import '../repositories/timetable_repository.dart';

class UpdateSchedule {
  final TimetableRepository repository;
  UpdateSchedule(this.repository);
  Future<void> call(ClassSchedule schedule) => repository.updateSchedule(schedule);
}