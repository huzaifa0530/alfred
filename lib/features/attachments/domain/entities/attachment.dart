class Attachment {
  final int id;
  final int noteId;
  final String type;
  final String name;
  final String path;
  final String? mimeType;
  final int? sizeBytes;
  final DateTime createdAt;

  const Attachment({
    required this.id,
    required this.noteId,
    required this.type,
    required this.name,
    required this.path,
    this.mimeType,
    this.sizeBytes,
    required this.createdAt,
  });

  bool get isImage => type == 'image';

  bool get isFile => type == 'file';

  bool get isVoice => type == 'voice';

  Attachment copyWith({
    int? id,
    int? noteId,
    String? type,
    String? name,
    String? path,
    String? mimeType,
    int? sizeBytes,
    DateTime? createdAt,
  }) {
    return Attachment(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      type: type ?? this.type,
      name: name ?? this.name,
      path: path ?? this.path,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}