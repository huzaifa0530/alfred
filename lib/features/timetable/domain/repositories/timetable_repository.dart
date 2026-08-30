import '../entities/class_schedule.dart';


abstract interface class TimetableRepository {
  Stream<List<ClassSchedule>> watchAllSchedules();
  Stream<List<ClassSchedule>> watchSchedulesForDay(int weekday);
  Future<List<ClassSchedule>> getAllSchedulesOnce(); // add this
  Future<ClassSchedule?> getSchedule(int id);
  Future<int> createSchedule(ClassSchedule schedule);
  Future<void> updateSchedule(ClassSchedule schedule);
  Future<void> deleteSchedule(int id);
}