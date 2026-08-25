import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/daos/attachments_dao.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/storage/file_storage_service.dart';
import '../../../../core/storage/storage_providers.dart';

import '../../data/datasources/attachment_picker.dart';
import '../../data/datasources/attachments_local_datasource.dart';
import '../../data/repositories/attachments_repository_impl.dart';
import '../../domain/repositories/attachments_repository.dart';

final attachmentPickerProvider =
    Provider<AttachmentPicker>((ref) {
  return AttachmentPicker();
});

final attachmentsDaoProvider =
    Provider<AttachmentsDao>((ref) {
  final database =
      ref.watch(appDatabaseProvider);

  return AttachmentsDao(database);
});

final attachmentsLocalDataSourceProvider =
    Provider<AttachmentsLocalDataSource>((ref) {
  return AttachmentsLocalDataSource(
    ref.watch(attachmentsDaoProvider),
  );
});

final attachmentsRepositoryProvider =
    Provider<AttachmentsRepository>((ref) {
  return AttachmentsRepositoryImpl(
    ref.watch(
      attachmentsLocalDataSourceProvider,
    ),
  );
});

final attachmentStorageProvider =
    Provider<FileStorageService>((ref) {
  return ref.watch(
    fileStorageServiceProvider,
  );
});