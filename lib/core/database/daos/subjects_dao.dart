import 'package:alfred/core/database/database_tables/attendance_table.dart';
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../database_tables/subjects_table.dart';
import '../database_tables/class_schedules_table.dart';
import '../database_tables/mark_components_table.dart';
import '../database_tables/marks_table.dart';
import '../database_tables/notes_table.dart';
import '../database_tables/attachments_table.dart';

part 'subjects_dao.g.dart';

@DriftAccessor(
  tables: [
    Subjects,
    ClassSchedules,
    MarkComponents,
    Marks,
    Notes,
    Attachments,
    AttendanceRecords,
  ],
)
class SubjectsDao extends DatabaseAccessor<AppDatabase>
    with _$SubjectsDaoMixin {
  SubjectsDao(super.db);

  Future<List<String>> deleteAllSubjects() async {
    return transaction(() async {
      final allNotes = await select(notes).get();

      final noteIds = allNotes.map((note) => note.id).toList();

      final attachmentPaths = <String>[];

      if (noteIds.isNotEmpty) {
        final allAttachments = await (select(
          attachments,
        )..where((attachment) => attachment.noteId.isIn(noteIds))).get();

        attachmentPaths.addAll(
          allAttachments
              .map((attachment) => attachment.path)
              .where((path) => path.isNotEmpty),
        );

        await delete(attachments).go();
      }

      await delete(notes).go();
      await delete(marks).go();
      await delete(markComponents).go();
      await delete(attendanceRecords).go();
      await delete(classSchedules).go();
      await delete(subjects).go();

      return attachmentPaths;
    });
  }

  Stream<List<Subject>> watchAllSubjects() {
    return select(subjects).watch();
  }

  Future<List<Subject>> getAllSubjects() {
    return select(subjects).get();
  }

  Future<Subject?> getSubjectById(int id) {
    return (select(
      subjects,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertSubject(SubjectsCompanion subject) {
    return into(subjects).insert(subject);
  }

  Future<bool> updateSubject(SubjectsCompanion subject) async {
    return await update(subjects).replace(subject);
  }

  Future<List<String>> deleteSubject(int subjectId) async {
    return transaction(() async {
      final subjectNotes = await (select(
        notes,
      )..where((note) => note.subjectId.equals(subjectId))).get();

      final noteIds = subjectNotes.map((note) => note.id).toList();

      final attachmentPaths = <String>[];

      if (noteIds.isNotEmpty) {
        final subjectAttachments = await (select(
          attachments,
        )..where((attachment) => attachment.noteId.isIn(noteIds))).get();

        attachmentPaths.addAll(
          subjectAttachments
              .map((attachment) => attachment.path)
              .where((path) => path.isNotEmpty),
        );

        await (delete(
          attachments,
        )..where((attachment) => attachment.noteId.isIn(noteIds))).go();
      }

      await (delete(
        notes,
      )..where((note) => note.subjectId.equals(subjectId))).go();

      await (delete(
        marks,
      )..where((mark) => mark.subjectId.equals(subjectId))).go();

      await (delete(
        markComponents,
      )..where((component) => component.subjectId.equals(subjectId))).go();

      await (delete(
        attendanceRecords,
      )..where((attendance) => attendance.subjectId.equals(subjectId))).go();

      await (delete(
        classSchedules,
      )..where((schedule) => schedule.subjectId.equals(subjectId))).go();

      await (delete(
        subjects,
      )..where((subject) => subject.id.equals(subjectId))).go();

      return attachmentPaths;
    });
  }
}
