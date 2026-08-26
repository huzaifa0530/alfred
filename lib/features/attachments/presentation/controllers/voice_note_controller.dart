import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/file_storage_service.dart';
import '../../data/datasources/audio_recorder_service.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/repositories/attachments_repository.dart';
import 'attachment_providers.dart';
import 'audio_providers.dart';

final voiceNoteControllerProvider =
    Provider.family<VoiceNoteController, int>(
  (ref, noteId) {
    return VoiceNoteController(
      noteId: noteId,
      recorder: ref.watch(
        audioRecorderProvider,
      ),
      repository: ref.watch(
        attachmentsRepositoryProvider,
      ),
      storage: ref.watch(
        attachmentStorageProvider,
      ),
    );
  },
);

class VoiceNoteController {
  final int noteId;
  final AudioRecorderService _recorder;
  final AttachmentsRepository _repository;
  final FileStorageService _storage;

  VoiceNoteController({
    required this.noteId,
    required AudioRecorderService recorder,
    required AttachmentsRepository repository,
    required FileStorageService storage,
  })  : _recorder = recorder,
        _repository = repository,
        _storage = storage;

  Future<void> startRecording() async {
    await _recorder.start();
  }

  Future<bool> isRecording() {
    return _recorder.isRecording();
  }

  Future<void> stopRecording() async {
    final temporaryPath =
        await _recorder.stop();

    if (temporaryPath == null) {
      return;
    }

    final source = File(temporaryPath);

    if (!await source.exists()) {
      return;
    }

    final fileName =
        'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    final storedPath =
        await _storage.saveAudio(
      source: source,
      fileName: fileName,
    );

    final attachment = Attachment(
      id: 0,
      noteId: noteId,
      type: 'voice',
      name: fileName,
      path: storedPath,
      mimeType: 'audio/mp4',
      sizeBytes:
          await _storage.getFileSize(
        storedPath,
      ),
      createdAt: DateTime.now(),
    );

    await _repository.createAttachment(
      attachment,
    );

    await source.delete();
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
  }
}