import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/subject.dart';
import '../models/subject_model.dart';

class SubjectMapper {
  const SubjectMapper._();

  static SubjectModel fromDatabase(db.Subject data) {
    return SubjectModel(
      id: data.id,
      name: data.name,
      code: data.code,
      instructor: data.instructor,
      room: data.room,
      color: data.color,
      isActive: data.isActive,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  static db.SubjectsCompanion toInsertCompanion(Subject subject) {
    return db.SubjectsCompanion.insert(
      name: subject.name,
      code: Value(subject.code),
      instructor: Value(subject.instructor),
      room: Value(subject.room),
      color: Value(subject.color),
      isActive: Value(subject.isActive),
    );
  }

  static db.SubjectsCompanion toUpdateCompanion(Subject subject) {
    return db.SubjectsCompanion(
      id: Value(subject.id),
      name: Value(subject.name),
      code: Value(subject.code),
      instructor: Value(subject.instructor),
      room: Value(subject.room),
      color: Value(subject.color),
      isActive: Value(subject.isActive),
      updatedAt: Value(subject.updatedAt),
    );
  }
}