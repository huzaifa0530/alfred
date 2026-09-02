import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../../core/database/daos/attendance_dao.dart';
import '../../domain/entities/attendance_record.dart';

import '../../data/datasources/attendance_local_datasource.dart';
import '../../data/repositories/attendance_repository_impl.dart';

import '../../domain/repositories/attendance_repository.dart';
import '../../domain/usecases/create_attendance.dart';
import '../../domain/usecases/update_attendance.dart';
import '../../domain/usecases/delete_attendance.dart';
import '../../domain/usecases/get_attendance.dart';
import '../../domain/usecases/get_attendance_summary.dart';
import '../../domain/usecases/get_attendance_for_schedule.dart';

/// DAO
final attendanceRecordsDaoProvider = Provider<AttendanceDao>((ref) {
  return AttendanceDao(ref.watch(appDatabaseProvider));
});

/// Local datasource
final attendanceLocalDataSourceProvider =
    Provider<AttendanceLocalDataSource>((ref) {
  return AttendanceLocalDataSource(
    ref.watch(attendanceRecordsDaoProvider),
  );
});

/// Repository
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepositoryImpl(
    ref.watch(attendanceLocalDataSourceProvider),
  );
});

/// Create (upsert entry point used by the mark-attendance flow)
final createAttendanceProvider = Provider<CreateAttendance>((ref) {
  return CreateAttendance(ref.watch(attendanceRepositoryProvider));
});

/// Update
final updateAttendanceProvider = Provider<UpdateAttendance>((ref) {
  return UpdateAttendance(ref.watch(attendanceRepositoryProvider));
});

/// Delete
final deleteAttendanceProvider = Provider<DeleteAttendance>((ref) {
  return DeleteAttendance(ref.watch(attendanceRepositoryProvider));
});

/// Get attendance (stream, per subject — dashboard use)
final getAttendanceProvider = Provider<GetAttendance>((ref) {
  return GetAttendance(ref.watch(attendanceRepositoryProvider));
});

/// Get attendance for a single scheduled class + date
final getAttendanceForScheduleProvider =
    Provider<GetAttendanceForSchedule>((ref) {
  return GetAttendanceForSchedule(ref.watch(attendanceRepositoryProvider));
});

/// Attendance summary
final getAttendanceSummaryProvider = Provider<GetAttendanceSummary>((ref) {
  return GetAttendanceSummary(ref.watch(attendanceRepositoryProvider));
});

/// Attendance records for a specific subject (drives the dashboard,
/// auto-updates via Drift's underlying stream)
final attendanceForSubjectProvider =
    StreamProvider.family<List<AttendanceRecord>, int>(
  (ref, subjectId) {
    return ref.watch(getAttendanceProvider)(subjectId);
  },
);

/// Key for looking up a single class's attendance on a specific date.
typedef ScheduleDateKey = ({int scheduleId, DateTime date});

/// Attendance record (if any) for one scheduled class on one date.
/// One-shot Future, not a stream — invalidate it after marking.
final attendanceForScheduleProvider =
    FutureProvider.family<AttendanceRecord?, ScheduleDateKey>(
  (ref, key) {
    return ref.watch(getAttendanceForScheduleProvider)(
      scheduleId: key.scheduleId,
      date: key.date,
    );
  },
);