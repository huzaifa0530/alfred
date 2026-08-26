import '../../domain/entities/class_schedule.dart';
import '../../domain/repositories/timetable_repository.dart';
import '../datasources/timetable_local_datasource.dart';

class TimetableRepositoryImpl
    implements TimetableRepository {
  final TimetableLocalDataSource _local;

  TimetableRepositoryImpl(this._local);

  @override
  Stream<List<ClassSchedule>>
      watchAllSchedules() {
    return _local.watchAllSchedules();
  }

  @override
  Stream<List<ClassSchedule>>
      watchSchedulesForDay(
    int weekday,
  ) {
    return _local.watchSchedulesForDay(
      weekday,
    );
  }

  @override
  Future<ClassSchedule?> getSchedule(
    int id,
  ) {
    return _local.getSchedule(id);
  }

  @override
  Future<int> createSchedule(
    ClassSchedule schedule,
  ) {
    return _local.createSchedule(
      schedule,
    );
  }

  @override
  Future<void> updateSchedule(
    ClassSchedule schedule,
  ) {
    return _local.updateSchedule(
      schedule,
    );
  }

  @override
  Future<void> deleteSchedule(
    int id,
  ) {
    return _local.deleteSchedule(id);
  }
}