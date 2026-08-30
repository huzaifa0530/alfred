import '../../../../core/database/daos/class_schedules_dao.dart';
import '../../domain/entities/class_schedule.dart';
import '../mappers/timetable_mapper.dart';

class TimetableLocalDataSource {
  final ClassSchedulesDao _dao;

  TimetableLocalDataSource(this._dao);

  Stream<List<ClassSchedule>> watchAllSchedules() {
    return _dao.watchAllSchedules().map(
      (items) =>
          items.map<ClassSchedule>(TimetableMapper.fromDatabase).toList(),
    );
  }

  Stream<List<ClassSchedule>> watchSchedulesForDay(int weekday) {
    return _dao
        .watchSchedulesForDay(weekday)
        .map(
          (items) =>
              items.map<ClassSchedule>(TimetableMapper.fromDatabase).toList(),
        );
  }

  Future<ClassSchedule?> getSchedule(int id) async {
    final data = await _dao.getScheduleById(id);

    if (data == null) return null;

    return TimetableMapper.fromDatabase(data);
  }

  Future<int> createSchedule(ClassSchedule schedule) {
    return _dao.insertSchedule(
      TimetableMapper.toInsertCompanion(schedule), // was toCompanion
    );
  }

  Future<void> updateSchedule(ClassSchedule schedule) async {
    await _dao.updateSchedule(
      TimetableMapper.toUpdateCompanion(schedule), // was toCompanion
    );
  }

  Future<void> deleteSchedule(int id) async {
    await _dao.deleteSchedule(id);
  }

  Future<List<ClassSchedule>> getAllSchedulesOnce() async {
    final items = await _dao.getAllSchedulesOnce();
    return items.map<ClassSchedule>(TimetableMapper.fromDatabase).toList();
  }
}
