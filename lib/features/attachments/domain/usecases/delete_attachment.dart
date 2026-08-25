import '../repositories/attachments_repository.dart';

class DeleteAttachment {
  final AttachmentsRepository _repository;

  DeleteAttachment(this._repository);

  Future<void> call(int id) {
    return _repository.deleteAttachment(id);
  }
}