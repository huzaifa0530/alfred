import 'dart:io';

import 'package:alfred/core/database/daos/attachments_dao.dart';
import 'package:alfred/core/database/daos/class_schedules_dao.dart';
import 'package:alfred/core/database/daos/marks_dao.dart';
import 'package:alfred/core/database/daos/notes_dao.dart';
import 'package:alfred/core/database/daos/events_dao.dart';
import 'package:alfred/core/database/daos/attendance_dao.dart';

import 'package:alfred/core/database/database_tables/attachments_table.dart';
import 'package:alfred/core/database/database_tables/attendance_table.dart';
import 'package:alfred/core/database/database_tables/class_schedules_table.dart';
import 'package:alfred/core/database/database_tables/mark_components_table.dart';
import 'package:alfred/core/database/database_tables/marks_table.dart';
import 'package:alfred/core/database/database_tables/notes_table.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/subjects_dao.dart';
import 'database_tables/subjects_table.dart';
import 'database_tables/events_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Subjects,
    Notes,
    Attachments,
    Events,
    ClassSchedules,
    AttendanceRecords,
    MarkComponents,
    Marks,
  ],
  daos: [
    SubjectsDao,
    NotesDao,
    AttachmentsDao,
    EventsDao,
    ClassSchedulesDao,
    AttendanceDao,
    MarksDao
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(notes);
      }
      if (from < 3) {
        await m.createTable(attachments);
      }
      if (from < 4) {
        await m.createTable(events);
      }
      if (from < 5) {
        await m.createTable(classSchedules);
      }
      if (from < 6) {
        await m.createTable(attendanceRecords);
      }
      if (from < 7) {
        await m.createTable(markComponents);
        await m.createTable(marks);

      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();

    final file = File(p.join(directory.path, 'alfred.sqlite'));

    return NativeDatabase.createInBackground(file);
  });
}
