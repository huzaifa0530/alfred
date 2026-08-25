import 'dart:io';

import 'package:alfred/core/storage/file_storage_service.dart';
import 'package:alfred/features/attachments/domain/repositories/attachments_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../attachments/domain/entities/attachment.dart';
import '../../../attachments/presentation/controllers/attachment_providers.dart';
import '../../domain/entities/note.dart';
import '../../domain/usecases/create_note.dart';
import '../../domain/usecases/delete_note.dart';
import '../../domain/usecases/get_notes.dart';
import 'notes_providers.dart';

final notesControllerProvider = Provider.family<NotesController, int>((
  ref,
  subjectId,
) {
  return NotesController(
    subjectId: subjectId,
    getNotes: ref.watch(getNotesProvider),
    createNote: ref.watch(createNoteProvider),
    deleteNote: ref.watch(deleteNoteProvider),
    attachmentRepository: ref.watch(attachmentsRepositoryProvider),
    attachmentStorage: ref.watch(attachmentStorageProvider),
  );
});

class NotesController {
  final int subjectId;

  final GetNotes _getNotes;
  final CreateNote _createNote;
  final DeleteNote _deleteNote;

  final AttachmentsRepository _attachmentRepository;
  final FileStorageService _attachmentStorage;
  NotesController({
    required this.subjectId,
    required GetNotes getNotes,
    required CreateNote createNote,
    required DeleteNote deleteNote,
    required AttachmentsRepository attachmentRepository,
    required FileStorageService attachmentStorage,
    
  }) : _getNotes = getNotes,
       _createNote = createNote,
       _deleteNote = deleteNote,
       _attachmentRepository = attachmentRepository,
       _attachmentStorage = attachmentStorage;

  Stream<List<Note>> watchNotes() {
    return _getNotes(subjectId);
  }

  Future<int> createTextNote(String content) async {
    final cleaned = content.trim();

    if (cleaned.isEmpty) {
      throw ArgumentError('Note content cannot be empty.');
    }

    final now = DateTime.now();

    final note = Note(
      id: 0,
      subjectId: subjectId,
      content: cleaned,
      noteType: 'text',
      createdAt: now,
      updatedAt: now,
    );

    return _createNote(note);
  }

  Future<int> createNoteWithAttachments({
    required String content,
    required List<File> files,
  }) async {
    final cleaned = content.trim();

    if (cleaned.isEmpty && files.isEmpty) {
      throw ArgumentError('Note must contain text or an attachment.');
    }

    final now = DateTime.now();

    final note = Note(
      id: 0,
      subjectId: subjectId,
      content: cleaned,
      noteType: files.isEmpty ? 'text' : 'mixed',
      createdAt: now,
      updatedAt: now,
    );

    final noteId = await _createNote(note);

    for (final file in files) {
      await _saveAttachment(noteId: noteId, file: file);
    }

    return noteId;
  }

  Future<void> _saveAttachment({
    required int noteId,
    required File file,
  }) async {
    final originalName = file.uri.pathSegments.last;

    final extension = originalName.split('.').last.toLowerCase();

    final isImage = const [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
    ].contains(extension);

    final storedPath = isImage
        ? await _attachmentStorage.saveImage(
            source: file,
            fileName: originalName,
          )
        : await _attachmentStorage.saveFile(
            source: file,
            fileName: originalName,
          );

    final attachment = Attachment(
      id: 0,
      noteId: noteId,
      type: isImage ? 'image' : 'file',
      name: originalName,
      path: storedPath,
      mimeType: isImage ? 'image/$extension' : null,
      sizeBytes: await _attachmentStorage.getFileSize(storedPath),
      createdAt: DateTime.now(),
    );

    await _attachmentRepository.createAttachment(attachment);
  }

  Future<void> deleteNote(int id) async {
    await _deleteNote(id);
  }
}
