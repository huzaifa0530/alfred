import '../entities/mark.dart';
import '../entities/mark_component.dart';

abstract class MarksRepository {
  // ============================================================
  // MARK COMPONENTS
  // ============================================================

  Future<int> createMarkComponent(
    MarkComponent component,
  );

  Future<bool> updateMarkComponent(
    MarkComponent component,
  );

  Future<void> deleteMarkComponent(
    int id,
  );

  Stream<List<MarkComponent>> watchComponentsForSubject(
    int subjectId,
  );

  Future<List<MarkComponent>> getComponentsForSubject(
    int subjectId,
  );

  Future<MarkComponent?> getMarkComponent(
    int id,
  );

  // ============================================================
  // MARKS
  // ============================================================

  Future<int> createMark(
    Mark mark,
  );

  Future<bool> updateMark(
    Mark mark,
  );

  Future<void> deleteMark(
    int id,
  );

  Future<Mark?> getMark({
    required int subjectId,
    required int componentId,
  });

  Future<void> saveMark(
    Mark mark,
  );

  Stream<List<Mark>> watchMarks();

  Stream<List<Mark>> watchMarksForSubject(
    int subjectId,
  );

  Future<List<Mark>> getMarksForSubject(
    int subjectId,
  );
}