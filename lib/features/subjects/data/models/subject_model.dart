import '../../domain/entities/subject.dart';

class SubjectModel extends Subject {
  const SubjectModel({
    required super.id,
    required super.name,
    super.code,
    super.instructor,
    super.room,
    super.color,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SubjectModel.fromEntity(Subject subject) {
    return SubjectModel(
      id: subject.id,
      name: subject.name,
      code: subject.code,
      instructor: subject.instructor,
      room: subject.room,
      color: subject.color,
      isActive: subject.isActive,
      createdAt: subject.createdAt,
      updatedAt: subject.updatedAt,
    );
  }

  Subject toEntity() {
    return Subject(
      id: id,
      name: name,
      code: code,
      instructor: instructor,
      room: room,
      color: color,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}