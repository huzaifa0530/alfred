import '../entities/subject.dart';

abstract interface class SubjectsRepository {
  Stream<List<Subject>> watchSubjects();

  Future<List<Subject>> getSubjects();

  Future<Subject?> getSubject(int id);

  Future<int> createSubject(Subject subject);

  Future<bool> updateSubject(Subject subject);
  Future<List<String>> deleteSubject(int id);
  Future<List<String>> deleteAllSubjects();


}
