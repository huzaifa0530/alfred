import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/mark_component.dart';

extension MarkComponentMapper on db.MarkComponent {
  MarkComponent toEntity() {
    return MarkComponent(
      id: id,
      subjectId: subjectId,
      name: name,
      type: type,
      maxMarks: maxMarks,
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }
}

extension MarkComponentCompanionMapper on MarkComponent {
  db.MarkComponentsCompanion toInsertCompanion() {
    return db.MarkComponentsCompanion.insert(
      subjectId: subjectId,
      name: name,
      type: Value(type),
      maxMarks: maxMarks,
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  db.MarkComponentsCompanion toUpdateCompanion() {
    return db.MarkComponentsCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      name: Value(name),
      type: Value(type),
      maxMarks: Value(maxMarks),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }
}
