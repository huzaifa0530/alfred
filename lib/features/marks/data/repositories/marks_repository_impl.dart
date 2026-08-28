import '../../domain/entities/mark.dart';
import '../../domain/entities/mark_component.dart';
import '../../domain/repositories/marks_repository.dart';
import '../datasources/marks_local_datasource.dart';

class MarksRepositoryImpl implements MarksRepository {
  final MarksLocalDataSource localDataSource;

  MarksRepositoryImpl(this.localDataSource);

  @override
  Future<int> createMarkComponent(MarkComponent component) {
    return localDataSource.createMarkComponent(component);
  }

  @override
  Future<bool> updateMarkComponent(MarkComponent component) {
    return localDataSource.updateMarkComponent(component);
  }

  @override
  Future<void> deleteMarkComponent(int id) {
    return localDataSource.deleteMarkComponent(id);
  }

  @override
  Stream<List<MarkComponent>> watchComponentsForSubject(int subjectId) {
    return localDataSource.watchComponentsForSubject(subjectId);
  }

  @override
  Future<List<MarkComponent>> getComponentsForSubject(int subjectId) {
    return localDataSource.getComponentsForSubject(subjectId);
  }

  @override
  Future<MarkComponent?> getMarkComponent(int id) {
    return localDataSource.getMarkComponent(id);
  }

  // ============================================================
  // WATCH ALL MARKS
  // ============================================================

  @override
  Stream<List<Mark>> watchMarks() {
    return localDataSource.watchAllMarks();
  }

  // ============================================================
  // WATCH MARKS FOR SUBJECT
  // ============================================================

  @override
  Stream<List<Mark>> watchMarksForSubject(int subjectId) {
    return localDataSource.watchMarksForSubject(subjectId);
  }

  @override
  Future<List<Mark>> getMarksForSubject(int subjectId) {
    return localDataSource.getMarksForSubject(subjectId);
  }

  // ============================================================
  // GET SINGLE MARK
  // ============================================================

  @override
  Future<Mark?> getMark({
    required int subjectId,
    required int componentId,
  }) {
    return localDataSource.getMark(
      subjectId: subjectId,
      componentId: componentId,
    );
  }

  // ============================================================
  // CREATE MARK
  // ============================================================

  @override
  Future<int> createMark(Mark mark) {
    return localDataSource.createMark(mark);
  }

  // ============================================================
  // UPDATE MARK
  // ============================================================

  @override
  Future<bool> updateMark(Mark mark) {
    return localDataSource.updateMark(mark);
  }

  // ============================================================
  // DELETE MARK
  // ============================================================

  @override
  Future<void> deleteMark(int id) {
    return localDataSource.deleteMark(id);
  }

  // ============================================================
  // SAVE / UPSERT MARK
  // ============================================================

  @override
  Future<void> saveMark(Mark mark) async {
    await localDataSource.saveMark(
      subjectId: mark.subjectId,
      componentId: mark.componentId,
      obtainedMarks: mark.obtainedMarks,
    );
  }
}