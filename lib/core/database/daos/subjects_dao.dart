import 'package:drift/drift.dart';

import '../app_database.dart';
import '../database_tables/subjects_table.dart';

part 'subjects_dao.g.dart';

@DriftAccessor(
  tables: [
    Subjects,
  ],
)
class SubjectsDao extends DatabaseAccessor<AppDatabase>
    with _$SubjectsDaoMixin {
  SubjectsDao(super.db);

  Stream<List<Subject>> watchAllSubjects() {
    return select(subjects).watch();
  }

  Future<List<Subject>> getAllSubjects() {
    return select(subjects).get();
  }

  Future<Subject?> getSubjectById(int id) {
    return (select(subjects)
          ..where(
            (table) => table.id.equals(id),
          ))
        .getSingleOrNull();
  }

  Future<int> insertSubject(SubjectsCompanion subject) {
    return into(subjects).insert(subject);
  }

  Future<bool> updateSubject(SubjectsCompanion subject) async {
    return await update(subjects).write(subject) > 0;
  }

  Future<int> deleteSubject(int id) {
    return (delete(subjects)
          ..where(
            (table) => table.id.equals(id),
          ))
        .go();
  }
}