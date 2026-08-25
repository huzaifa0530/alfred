import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as database;
import '../../domain/entities/attachment.dart' as domain;

class AttachmentMapper {
  const AttachmentMapper._();

  static domain.Attachment fromDatabase(
    database.Attachment data,
  ) {
    return domain.Attachment(
      id: data.id,
      noteId: data.noteId,
      type: data.type,
      name: data.name,
      path: data.path,
      mimeType: data.mimeType,
      sizeBytes: data.sizeBytes,
      createdAt: data.createdAt,
    );
  }

  static database.AttachmentsCompanion toInsertCompanion(
    domain.Attachment attachment,
  ) {
    return database.AttachmentsCompanion.insert(
      noteId: attachment.noteId,
      type: attachment.type,
      name: attachment.name,
      path: attachment.path,
      mimeType: Value(attachment.mimeType),
      sizeBytes: Value(attachment.sizeBytes),
    );
  }
}