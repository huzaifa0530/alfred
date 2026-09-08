import 'package:alfred/core/database/database_providers.dart';
import 'package:alfred/features/attendance/domain/usecases/get_attendance_summary.dart';
import 'package:alfred/features/attendance/presentation/controllers/attendance_providers.dart';
import 'package:alfred/features/subjects/presentation/controllers/subjects_controller.dart';
import 'package:alfred/features/timetable/domain/usecases/get_subject_calendar_statuses.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/daos/class_schedules_dao.dart';
import 'package:flutter/material.dart';

import '../../data/datasources/timetable_local_datasource.dart';
import '../../data/repositories/timetable_repository_impl.dart';
import '../../domain/entities/class_schedule.dart';
import '../../domain/repositories/timetable_repository.dart';

import '../../domain/usecases/create_schedule.dart';
import '../../domain/usecases/update_schedule.dart';
import '../../domain/usecases/delete_schedule.dart';

final classSchedulesDaoProvider = Provider<ClassSchedulesDao>((ref) {
  return ClassSchedulesDao(ref.watch(appDatabaseProvider));
});

final timetableLocalDataSourceProvider = Provider<TimetableLocalDataSource>((
  ref,
) {
  return TimetableLocalDataSource(ref.watch(classSchedulesDaoProvider));
});

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepositoryImpl(ref.watch(timetableLocalDataSourceProvider));
});

final allTimetableProvider = StreamProvider<List<ClassSchedule>>((ref) {
  return ref.watch(timetableRepositoryProvider).watchAllSchedules();
});

final todayTimetableProvider = StreamProvider<List<ClassSchedule>>((ref) {
  final weekday = DateTime.now().weekday;
  final allSchedulesDebug = ref.watch(allTimetableProvider);
  allSchedulesDebug.whenData((all) {
    for (final s in all) {
      debugPrint(
        'ALL → subjectId=${s.subjectId} weekday=${s.weekday} '
        'start=${s.startTime} active=${s.isActive}',
      );
    }
  });
  return ref.watch(timetableRepositoryProvider).watchSchedulesForDay(weekday);
});

final timetableForDayProvider = StreamProvider.family<List<ClassSchedule>, int>(
  (ref, weekday) {
    return ref.watch(timetableRepositoryProvider).watchSchedulesForDay(weekday);
  },
);

final createScheduleProvider = Provider<CreateSchedule>((ref) {
  return CreateSchedule(ref.watch(timetableRepositoryProvider));
});
final updateScheduleProvider = Provider<UpdateSchedule>((ref) {
  return UpdateSchedule(ref.watch(timetableRepositoryProvider));
});
final deleteScheduleProvider = Provider<DeleteSchedule>((ref) {
  return DeleteSchedule(ref.watch(timetableRepositoryProvider));
});

final timetableSnapshotProvider = FutureProvider<List<ClassSchedule>>((ref) {
  return ref.watch(timetableRepositoryProvider).getAllSchedulesOnce();
});
final schedulesForSubjectProvider = Provider.family<List<ClassSchedule>, int>((
  ref,
  subjectId,
) {
  return ref
      .watch(allTimetableProvider)
      .maybeWhen(
        data: (schedules) =>
            schedules.where((s) => s.subjectId == subjectId).toList(),
        orElse: () => const [],
      );
});
final getSubjectCalendarStatusesProvider = Provider<GetSubjectCalendarStatuses>(
  (ref) => GetSubjectCalendarStatuses(),
);
final overallAttendanceProvider =
    Provider<AsyncValue<SubjectAttendanceSummary>>((ref) {
      final subjectsAsync = ref.watch(subjectsControllerProvider);

      return subjectsAsync.when(
        loading: () => const AsyncLoading(),
        error: (e, st) => AsyncError(e, st),
        data: (subjects) {
          if (subjects.isEmpty) {
            return AsyncData(
              SubjectAttendanceSummary(
                present: 0,
                absent: 0,
                cancelled: 0,
                expected: 0,
              ),
            );
          }

          var present = 0;
          var absent = 0;
          var cancelled = 0;
          var expected = 0;
          var stillLoading = false;

          for (final subject in subjects) {
            final recordsAsync = ref.watch(
              attendanceForSubjectProvider(subject.id),
            );
            final schedules = ref.watch(
              schedulesForSubjectProvider(subject.id),
            );

            if (recordsAsync.isLoading) {
              stillLoading = true;
              continue;
            }

            recordsAsync.whenData((records) {
              final summary = ref
                  .read(getAttendanceSummaryProvider)
                  .call(
                    schedulesForSubject: schedules,
                    recordsForSubject: records,
                    asOf: DateTime.now(),
                  );
              present += summary.present;
              absent += summary.absent;
              cancelled += summary.cancelled;
              expected += summary.expected;
            });
          }

          if (stillLoading) return const AsyncLoading();

          return AsyncData(
            SubjectAttendanceSummary(
              present: present,
              absent: absent,
              cancelled: cancelled,
              expected: expected,
            ),
          );
        },
      );
    });
