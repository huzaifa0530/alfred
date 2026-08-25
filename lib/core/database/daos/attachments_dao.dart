import 'package:alfred/core/database/database_tables/attachments_table.dart';
import 'package:drift/drift.dart';

import '../app_database.dart';

part 'attachments_dao.g.dart';

@DriftAccessor(tables: [Attachments])
class AttachmentsDao
    extends DatabaseAccessor<AppDatabase>
    with _$AttachmentsDaoMixin {
  AttachmentsDao(super.db);

  Stream<List<Attachment>> watchAttachmentsForNote(
    int noteId,
  ) {
    return (select(attachments)
          ..where(
            (attachment) =>
                attachment.noteId.equals(noteId),
          )
          ..orderBy([
            (attachment) => OrderingTerm(
                  expression:
                      attachment.createdAt,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  Future<List<Attachment>>
      getAttachmentsForNote(
    int noteId,
  ) {
    return (select(attachments)
          ..where(
            (attachment) =>
                attachment.noteId.equals(noteId),
          )
          ..orderBy([
            (attachment) => OrderingTerm(
                  expression:
                      attachment.createdAt,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();
  }

  Future<Attachment?> getAttachmentById(
    int id,
  ) {
    return (select(attachments)
          ..where(
            (attachment) =>
                attachment.id.equals(id),
          ))
        .getSingleOrNull();
  }

  Future<int> insertAttachment(
    AttachmentsCompanion entry,
  ) {
    return into(attachments).insert(entry);
  }

  Future<int> deleteAttachment(int id) {
    return (delete(attachments)
          ..where(
            (attachment) =>
                attachment.id.equals(id),
          ))
        .go();
  }
}