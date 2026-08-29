import '../repositories/timetable_repository.dart';

class DeleteSchedule {
  final TimetableRepository repository;
  DeleteSchedule(this.repository);
  Future<void> call(int id) => repository.deleteSchedule(id);
}