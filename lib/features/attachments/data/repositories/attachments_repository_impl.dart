import '../../domain/entities/attachment.dart';
import '../../domain/repositories/attachments_repository.dart';
import '../datasources/attachments_local_datasource.dart';

class AttachmentsRepositoryImpl
    implements AttachmentsRepository {
  final AttachmentsLocalDataSource
      _localDataSource;

  AttachmentsRepositoryImpl(
    this._localDataSource,
  );

  @override
  Stream<List<Attachment>>
      watchAttachmentsForNote(int noteId) {
    return _localDataSource
        .watchAttachmentsForNote(noteId);
  }

  @override
  Future<List<Attachment>>
      getAttachmentsForNote(int noteId) {
    return _localDataSource
        .getAttachmentsForNote(noteId);
  }

  @override
  Future<Attachment?> getAttachment(int id) {
    return _localDataSource.getAttachment(id);
  }

  @override
  Future<int> createAttachment(
    Attachment attachment,
  ) {
    return _localDataSource
        .insertAttachment(attachment);
  }

  @override
  Future<void> deleteAttachment(int id) {
    return _localDataSource
        .deleteAttachment(id);
  }
}