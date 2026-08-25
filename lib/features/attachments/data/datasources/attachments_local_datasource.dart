import '../../../../core/database/daos/attachments_dao.dart';
import '../../domain/entities/attachment.dart';
import '../mappers/attachment_mapper.dart';

class AttachmentsLocalDataSource {
  final AttachmentsDao _dao;

  AttachmentsLocalDataSource(this._dao);

  Stream<List<Attachment>>
      watchAttachmentsForNote(
    int noteId,
  ) {
    return _dao
        .watchAttachmentsForNote(noteId)
        .map(
          (items) => items
              .map<Attachment>(
                AttachmentMapper.fromDatabase,
              )
              .toList(),
        );
  }

  Future<List<Attachment>>
      getAttachmentsForNote(
    int noteId,
  ) async {
    final items =
        await _dao.getAttachmentsForNote(noteId);

    return items
        .map<Attachment>(
          AttachmentMapper.fromDatabase,
        )
        .toList();
  }

  Future<Attachment?> getAttachment(
    int id,
  ) async {
    final item =
        await _dao.getAttachmentById(id);

    if (item == null) {
      return null;
    }

    return AttachmentMapper.fromDatabase(item);
  }

  Future<int> insertAttachment(
    Attachment attachment,
  ) {
    return _dao.insertAttachment(
      AttachmentMapper.toInsertCompanion(
        attachment,
      ),
    );
  }

  Future<void> deleteAttachment(int id) async {
    await _dao.deleteAttachment(id);
  }
}