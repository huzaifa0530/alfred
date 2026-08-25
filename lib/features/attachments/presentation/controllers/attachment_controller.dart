import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/file_storage_service.dart';
import '../../data/datasources/attachment_picker.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/repositories/attachments_repository.dart';
import 'attachment_providers.dart';

final attachmentControllerProvider =
    Provider.family<
        AttachmentController,
        int>((ref, noteId) {
  return AttachmentController(
    noteId: noteId,
    picker: ref.watch(
      attachmentPickerProvider,
    ),
    repository: ref.watch(
      attachmentsRepositoryProvider,
    ),
    storage: ref.watch(
      attachmentStorageProvider,
    ),
  );
});

class AttachmentController {
  final int noteId;

  final AttachmentPicker _picker;
  final AttachmentsRepository _repository;
  final FileStorageService _storage;

  AttachmentController({
    required this.noteId,
    required AttachmentPicker picker,
    required AttachmentsRepository repository,
    required FileStorageService storage,
  })  : _picker = picker,
        _repository = repository,
        _storage = storage;

  Stream<List<Attachment>> watchAttachments() {
    return _repository
        .watchAttachmentsForNote(noteId);
  }

  Future<void> pickCameraImage() async {
    final file =
        await _picker.pickFromCamera();

    if (file == null) {
      return;
    }

    await _saveImage(file);
  }

  Future<void> pickGalleryImage() async {
    final file =
        await _picker.pickFromGallery();

    if (file == null) {
      return;
    }

    await _saveImage(file);
  }

  Future<void> pickFile() async {
    final file =
        await _picker.pickFile();

    if (file == null) {
      return;
    }

    await _saveFile(file);
  }

  Future<void> _saveImage(File file) async {
    final originalName =
        file.uri.pathSegments.last;

    final storedPath =
        await _storage.saveImage(
      source: file,
      fileName: originalName,
    );

    final attachment = Attachment(
      id: 0,
      noteId: noteId,
      type: 'image',
      name: originalName,
      path: storedPath,
      mimeType: 'image/jpeg',
      sizeBytes: await _storage.getFileSize(
        storedPath,
      ),
      createdAt: DateTime.now(),
    );

    await _repository.createAttachment(
      attachment,
    );
  }

  Future<void> _saveFile(File file) async {
    final originalName =
        file.uri.pathSegments.last;

    final storedPath =
        await _storage.saveFile(
      source: file,
      fileName: originalName,
    );

    final attachment = Attachment(
      id: 0,
      noteId: noteId,
      type: 'file',
      name: originalName,
      path: storedPath,
      mimeType: _guessMimeType(originalName),
      sizeBytes: await _storage.getFileSize(
        storedPath,
      ),
      createdAt: DateTime.now(),
    );

    await _repository.createAttachment(
      attachment,
    );
  }

  Future<void> deleteAttachment(
    Attachment attachment,
  ) async {
    await _repository.deleteAttachment(
      attachment.id,
    );

    await _storage.deleteFile(
      attachment.path,
    );
  }

  String? _guessMimeType(String name) {
    final extension =
        name.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return 'application/pdf';

      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      case 'doc':
        return 'application/msword';

      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      case 'xls':
        return 'application/vnd.ms-excel';

      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      case 'txt':
        return 'text/plain';

      default:
        return null;
    }
  }
}