import '../../../../core/storage/file_storage_service.dart';
import '../repositories/subjects_repository.dart';

class DeleteSubject {
  final SubjectsRepository _repository;
  final FileStorageService _storage;

  DeleteSubject(
    this._repository,
    this._storage,
  );

  Future<void> call(int id) async {
    // Delete database records and get attachment paths.
    final attachmentPaths =
        await _repository.deleteSubject(id);

    // Delete physical files.
    for (final path in attachmentPaths) {
      await _storage.deleteFile(path);
    }
  }
}