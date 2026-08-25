import '../entities/attachment.dart';
import '../repositories/attachments_repository.dart';

class CreateAttachment {
  final AttachmentsRepository _repository;

  CreateAttachment(this._repository);

  Future<int> call(Attachment attachment) {
    return _repository.createAttachment(attachment);
  }
}