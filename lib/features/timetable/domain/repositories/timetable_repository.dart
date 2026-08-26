import '../entities/class_schedule.dart';

abstract interface class TimetableRepository {
  Stream<List<ClassSchedule>>
      watchAllSchedules();

  Stream<List<ClassSchedule>>
      watchSchedulesForDay(
    int weekday,
  );

  Future<ClassSchedule?> getSchedule(
    int id,
  );

  Future<int> createSchedule(
    ClassSchedule schedule,
  );

  Future<void> updateSchedule(
    ClassSchedule schedule,
  );

  Future<void> deleteSchedule(int id);
}