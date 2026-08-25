class Subject {
  final int id;
  final String name;
  final String? code;
  final String? instructor;
  final String? room;
  final String? color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subject({
    required this.id,
    required this.name,
    this.code,
    this.instructor,
    this.room,
    this.color,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Subject copyWith({
    int? id,
    String? name,
    String? code,
    String? instructor,
    String? room,
    String? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      instructor: instructor ?? this.instructor,
      room: room ?? this.room,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}