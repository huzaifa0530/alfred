import '../entities/attachment.dart';
import '../repositories/attachments_repository.dart';

class GetAttachment {
  final AttachmentsRepository _repository;

  GetAttachment(this._repository);

  Future<Attachment?> call(int id) {
    return _repository.getAttachment(id);
  }
}