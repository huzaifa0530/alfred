import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/mark.dart';

extension MarkMapper on db.Mark {
  Mark toEntity() {
    return Mark(
      id: id,
      subjectId: subjectId,
      componentId: componentId,
      obtainedMarks: obtainedMarks,
      updatedAt: updatedAt,
    );
  }
}

extension MarkCompanionMapper on Mark {
  // ============================================================
  // INSERT
  // ============================================================

  db.MarksCompanion toInsertCompanion() {
    return db.MarksCompanion.insert(
      subjectId: subjectId,
      componentId: componentId,
      obtainedMarks: Value(obtainedMarks),
      updatedAt: Value(updatedAt),
    );
  }

  // ============================================================
  // UPDATE
  // ============================================================

  db.MarksCompanion toUpdateCompanion() {
    return db.MarksCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      componentId: Value(componentId),
      obtainedMarks: Value(obtainedMarks),
      updatedAt: Value(updatedAt),
    );
  }
}