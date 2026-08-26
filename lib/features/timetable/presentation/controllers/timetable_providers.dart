import 'package:alfred/core/database/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/daos/class_schedules_dao.dart';

import '../../data/datasources/timetable_local_datasource.dart';
import '../../data/repositories/timetable_repository_impl.dart';
import '../../domain/entities/class_schedule.dart';
import '../../domain/repositories/timetable_repository.dart';

final classSchedulesDaoProvider =
    Provider<ClassSchedulesDao>((ref) {
  return ClassSchedulesDao(
    ref.watch(appDatabaseProvider),
  );
});

final timetableLocalDataSourceProvider =
    Provider<TimetableLocalDataSource>((ref) {
  return TimetableLocalDataSource(
    ref.watch(classSchedulesDaoProvider),
  );
});

final timetableRepositoryProvider =
    Provider<TimetableRepository>((ref) {
  return TimetableRepositoryImpl(
    ref.watch(
      timetableLocalDataSourceProvider,
    ),
  );
});

final allTimetableProvider =
    StreamProvider<List<ClassSchedule>>((ref) {
  return ref
      .watch(timetableRepositoryProvider)
      .watchAllSchedules();
});

final todayTimetableProvider =
    StreamProvider<List<ClassSchedule>>((ref) {
  final weekday = DateTime.now().weekday;

  return ref
      .watch(timetableRepositoryProvider)
      .watchSchedulesForDay(
        weekday,
      );
});

final timetableForDayProvider =
    StreamProvider.family<
        List<ClassSchedule>,
        int>((ref, weekday) {
  return ref
      .watch(timetableRepositoryProvider)
      .watchSchedulesForDay(
        weekday,
      );
});