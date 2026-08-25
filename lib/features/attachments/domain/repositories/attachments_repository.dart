import '../entities/attachment.dart';

abstract interface class AttachmentsRepository {
  Stream<List<Attachment>> watchAttachmentsForNote(
    int noteId,
  );

  Future<List<Attachment>> getAttachmentsForNote(
    int noteId,
  );

  Future<Attachment?> getAttachment(
    int id,
  );

  Future<int> createAttachment(
    Attachment attachment,
  );

  Future<void> deleteAttachment(
    int id,
  );
}