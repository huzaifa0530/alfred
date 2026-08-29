import '../entities/class_schedule.dart';
import '../repositories/timetable_repository.dart';

class CreateSchedule {
  final TimetableRepository repository;
  CreateSchedule(this.repository);
  Future<int> call(ClassSchedule schedule) => repository.createSchedule(schedule);
}