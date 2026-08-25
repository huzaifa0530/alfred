import '../../../../core/database/daos/subjects_dao.dart';
import '../../domain/entities/subject.dart';
import '../mappers/subject_mapper.dart';

class SubjectsLocalDataSource {
  final SubjectsDao _dao;

  SubjectsLocalDataSource(this._dao);

  Stream<List<Subject>> watchSubjects() {
    return _dao.watchAllSubjects().map(
          (items) => items
        .map<Subject>(SubjectMapper.fromDatabase)
              .toList(),
        );
  }

  Future<List<Subject>> getSubjects() async {
    final items = await _dao.getAllSubjects();

    return items
      .map<Subject>(SubjectMapper.fromDatabase)
        .toList();
  }

  Future<Subject?> getSubject(int id) async {
    final item = await _dao.getSubjectById(id);

    if (item == null) {
      return null;
    }

    return SubjectMapper.fromDatabase(item);
  }

  Future<int> insertSubject(Subject subject) {
    return _dao.insertSubject(
      SubjectMapper.toInsertCompanion(subject),
    );
  }

  Future<bool> updateSubject(Subject subject) {
    return _dao.updateSubject(
      SubjectMapper.toUpdateCompanion(subject),
    );
  }

  Future<int> deleteSubject(int id) {
    return _dao.deleteSubject(id);
  }
}