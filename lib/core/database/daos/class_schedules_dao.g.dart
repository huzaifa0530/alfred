// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_schedules_dao.dart';

// ignore_for_file: type=lint
mixin _$ClassSchedulesDaoMixin on DatabaseAccessor<AppDatabase> {
  $ClassSchedulesTable get classSchedules => attachedDatabase.classSchedules;
  ClassSchedulesDaoManager get managers => ClassSchedulesDaoManager(this);
}

class ClassSchedulesDaoManager {
  final _$ClassSchedulesDaoMixin _db;
  ClassSchedulesDaoManager(this._db);
  $$ClassSchedulesTableTableManager get classSchedules =>
      $$ClassSchedulesTableTableManager(
        _db.attachedDatabase,
        _db.classSchedules,
      );
}
