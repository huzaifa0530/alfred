import 'package:alfred/features/subjects/data/datasources/subjects_local_datasource.dart';

import '../../domain/entities/subject.dart';
import '../../domain/repositories/subjects_repository.dart';

class SubjectsRepositoryImpl implements SubjectsRepository {
  final SubjectsLocalDataSource _localDataSource;

  SubjectsRepositoryImpl(this._localDataSource);

  @override
  Stream<List<Subject>> watchSubjects() {
    return _localDataSource.watchSubjects();
  }

  @override
  Future<List<Subject>> getSubjects() {
    return _localDataSource.getSubjects();
  }

  @override
  Future<Subject?> getSubject(int id) {
    return _localDataSource.getSubject(id);
  }

  @override
  Future<int> createSubject(Subject subject) {
    return _localDataSource.insertSubject(subject);
  }

  @override
  Future<bool> updateSubject(Subject subject) {
    return _localDataSource.updateSubject(subject);
  }

  @override
  Future<void> deleteSubject(int id) async {
    await _localDataSource.deleteSubject(id);
  }
}