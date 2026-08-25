import 'dart:io';

import 'package:alfred/core/database/daos/attachments_dao.dart';
import 'package:alfred/core/database/daos/notes_dao.dart';
import 'package:alfred/core/database/database_tables/attachments_table.dart';
import 'package:alfred/core/database/database_tables/notes_table.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/subjects_dao.dart';
import 'database_tables/subjects_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Subjects, Notes, Attachments],
  daos: [SubjectsDao, NotesDao, AttachmentsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

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
