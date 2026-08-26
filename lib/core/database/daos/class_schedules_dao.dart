import 'package:alfred/core/database/database_tables/class_schedules_table.dart';
import 'package:drift/drift.dart';

import '../app_database.dart';

part 'class_schedules_dao.g.dart';

@DriftAccessor(tables: [ClassSchedules])
class ClassSchedulesDao
    extends DatabaseAccessor<AppDatabase>
    with _$ClassSchedulesDaoMixin {
  ClassSchedulesDao(super.db);

  Stream<List<ClassSchedule>>
      watchAllSchedules() {
    return (select(classSchedules)
          ..where(
            (schedule) =>
                schedule.isActive.equals(true),
          )
          ..orderBy([
            (schedule) => OrderingTerm(
                  expression:
                      schedule.weekday,
                  mode: OrderingMode.asc,
                ),
            (schedule) => OrderingTerm(
                  expression:
                      schedule.startTime,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  Stream<List<ClassSchedule>>
      watchSchedulesForDay(
    int weekday,
  ) {
    return (select(classSchedules)
          ..where(
            (schedule) =>
                schedule.weekday.equals(
                  weekday,
                ) &
                schedule.isActive.equals(true),
          )
          ..orderBy([
            (schedule) => OrderingTerm(
                  expression:
                      schedule.startTime,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  Future<ClassSchedule?>
      getScheduleById(int id) {
    return (select(classSchedules)
          ..where(
            (schedule) =>
                schedule.id.equals(id),
          ))
        .getSingleOrNull();
  }

  Future<int> insertSchedule(
    ClassSchedulesCompanion schedule,
  ) {
    return into(classSchedules)
        .insert(schedule);
  }

  Future<bool> updateSchedule(
    ClassSchedulesCompanion schedule,
  ) {
    return update(classSchedules)
        .replace(schedule);
  }

  Future<int> deleteSchedule(int id) {
    return (delete(classSchedules)
          ..where(
            (schedule) =>
                schedule.id.equals(id),
          ))
        .go();
  }
}