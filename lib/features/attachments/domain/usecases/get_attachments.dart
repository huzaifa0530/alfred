import '../entities/attachment.dart';
import '../repositories/attachments_repository.dart';

class GetAttachments {
  final AttachmentsRepository _repository;

  GetAttachments(this._repository);

  Future<List<Attachment>> call(int noteId) {
    return _repository.getAttachmentsForNote(noteId);
  }

  Stream<List<Attachment>> watch(int noteId) {
    return _repository.watchAttachmentsForNote(noteId);
  }
}