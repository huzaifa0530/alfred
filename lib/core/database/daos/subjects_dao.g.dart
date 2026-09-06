// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subjects_dao.dart';

// ignore_for_file: type=lint
mixin _$SubjectsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $ClassSchedulesTable get classSchedules => attachedDatabase.classSchedules;
  $MarkComponentsTable get markComponents => attachedDatabase.markComponents;
  $MarksTable get marks => attachedDatabase.marks;
  $NotesTable get notes => attachedDatabase.notes;
  $AttachmentsTable get attachments => attachedDatabase.attachments;
  $AttendanceRecordsTable get attendanceRecords =>
      attachedDatabase.attendanceRecords;
  SubjectsDaoManager get managers => SubjectsDaoManager(this);
}

class SubjectsDaoManager {
  final _$SubjectsDaoMixin _db;
  SubjectsDaoManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db.attachedDatabase, _db.subjects);
  $$ClassSchedulesTableTableManager get classSchedules =>
      $$ClassSchedulesTableTableManager(
        _db.attachedDatabase,
        _db.classSchedules,
      );
  $$MarkComponentsTableTableManager get markComponents =>
      $$MarkComponentsTableTableManager(
        _db.attachedDatabase,
        _db.markComponents,
      );
  $$MarksTableTableManager get marks =>
      $$MarksTableTableManager(_db.attachedDatabase, _db.marks);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db.attachedDatabase, _db.notes);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db.attachedDatabase, _db.attachments);
  $$AttendanceRecordsTableTableManager get attendanceRecords =>
      $$AttendanceRecordsTableTableManager(
        _db.attachedDatabase,
        _db.attendanceRecords,
      );
}
