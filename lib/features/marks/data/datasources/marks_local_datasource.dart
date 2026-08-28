import 'package:alfred/core/database/daos/marks_dao.dart';

import '../../domain/entities/mark.dart';
import '../../domain/entities/mark_component.dart';
import '../mappers/mark_component_mapper.dart';
import '../mappers/mark_mapper.dart';

class MarksLocalDataSource {
  final MarksDao dao;

  MarksLocalDataSource(this.dao);

  Future<int> createMarkComponent(MarkComponent component) {
    return dao.insertComponent(component.toInsertCompanion());
  }

  Future<bool> updateMarkComponent(MarkComponent component) {
    return dao.updateComponent(
      component.id,
      component.toUpdateCompanion(),
    );
  }

  Future<void> deleteMarkComponent(int id) {
    return dao.deleteComponent(id);
  }

  Stream<List<MarkComponent>> watchComponentsForSubject(int subjectId) {
    return dao.watchComponentsForSubject(subjectId).map(
          (records) => records
              .map((record) => record.toEntity())
              .toList(),
        );
  }

  Future<List<MarkComponent>> getComponentsForSubject(int subjectId) {
    return dao.getComponentsForSubject(subjectId).then(
          (records) => records
              .map((record) => record.toEntity())
              .toList(),
        );
  }

  Future<MarkComponent?> getMarkComponent(int id) async {
    final record = await dao.getComponent(id);
    return record?.toEntity();
  }

  // ============================================================
  // WATCH ALL MARKS
  // ============================================================

  Stream<List<Mark>> watchAllMarks() {
    return dao.watchAllMarks().map(
          (records) => records
              .map((record) => record.toEntity())
              .toList(),
        );
  }

  // ============================================================
  // WATCH MARKS FOR SUBJECT
  // ============================================================

  Stream<List<Mark>> watchMarksForSubject(int subjectId) {
    return dao.watchMarksForSubject(subjectId).map(
          (records) => records
              .map((record) => record.toEntity())
              .toList(),
        );
  }

    Future<List<Mark>> getMarksForSubject(int subjectId) {
      return dao.getMarksForSubject(subjectId).then(
        (records) => records
        .map((record) => record.toEntity())
        .toList(),
      );
    }

  // ============================================================
  // GET SINGLE MARK
  // ============================================================

  Future<Mark?> getMark({
    required int subjectId,
    required int componentId,
  }) async {
    final record = await dao.getMark(
      subjectId: subjectId,
      componentId: componentId,
    );

    return record?.toEntity();
  }

  // ============================================================
  // CREATE MARK
  // ============================================================

  Future<int> createMark(Mark mark) {
    return dao.insertMark(
      mark.toInsertCompanion(),
    );
  }

  // ============================================================
  // UPDATE MARK
  // ============================================================

  Future<bool> updateMark(Mark mark) {
    return dao.updateMark(
      mark.id,
      mark.toUpdateCompanion(),
    );
  }

  // ============================================================
  // DELETE MARK
  // ============================================================

  Future<void> deleteMark(int id) {
    return dao.deleteMark(id);
  }

  // ============================================================
  // SAVE / UPSERT MARK
  // ============================================================

  Future<int> saveMark({
    required int subjectId,
    required int componentId,
    required double? obtainedMarks,
  }) {
    return dao.saveMark(
      subjectId: subjectId,
      componentId: componentId,
      obtainedMarks: obtainedMarks,
    );
  }
}