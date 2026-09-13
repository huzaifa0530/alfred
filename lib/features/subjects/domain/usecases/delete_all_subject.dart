import '../../../../core/storage/file_storage_service.dart';
import '../repositories/subjects_repository.dart';

class DeleteAllSubjects {
  final SubjectsRepository _repository;
  final FileStorageService _storage;

  DeleteAllSubjects(
    this._repository,
    this._storage,
  );

  Future<void> call() async {
    final attachmentPaths =
        await _repository.deleteAllSubjects();

    for (final path in attachmentPaths) {
      await _storage.deleteFile(path);
    }
  }
}