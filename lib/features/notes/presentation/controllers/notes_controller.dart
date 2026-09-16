import 'dart:io';

import 'package:alfred/core/storage/file_storage_service.dart';
import 'package:alfred/features/notes/domain/usecases/move_note_to_subject.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../attachments/domain/entities/attachment.dart';
import '../../../attachments/domain/repositories/attachments_repository.dart';
import '../../../attachments/presentation/controllers/attachment_providers.dart';
import '../../domain/entities/note.dart';
import '../../domain/usecases/create_note.dart';
import '../../domain/usecases/delete_all_notes.dart';
import '../../domain/usecases/delete_note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/summarize_note.dart';
import '../../domain/usecases/update_note.dart';
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
    deleteAllNotes: ref.watch(deleteAllNotesProvider),
    updateNote: ref.watch(updateNoteProvider),
    attachmentRepository: ref.watch(attachmentsRepositoryProvider),
    attachmentStorage: ref.watch(attachmentStorageProvider),
    summarizeNote: ref.watch(summarizeNoteProvider),
    moveNoteToSubject: ref.watch(moveNoteToSubjectProvider),
  );
});

final deleteAllNotesProvider = Provider<DeleteAllNotes>((ref) {
  return DeleteAllNotes(ref.watch(notesRepositoryProvider));
});

final updateNoteProvider = Provider<UpdateNote>((ref) {
  return UpdateNote(ref.watch(notesRepositoryProvider));
});

class NotesController {
  late final MoveNoteToSubject _moveNoteToSubject;
  final int subjectId;

  final GetNotes _getNotes;
  final CreateNote _createNote;
  final DeleteNote _deleteNote;
  final DeleteAllNotes _deleteAllNotes;
  final UpdateNote _updateNote;
  final SummarizeNote _summarizeNote;

  final AttachmentsRepository _attachmentRepository;
  final FileStorageService _attachmentStorage;

  NotesController({
    required this.subjectId,
    required GetNotes getNotes,
    required CreateNote createNote,
    required DeleteNote deleteNote,
    required DeleteAllNotes deleteAllNotes,
    required UpdateNote updateNote,
    required AttachmentsRepository attachmentRepository,
    required FileStorageService attachmentStorage,
    required SummarizeNote summarizeNote,
    required MoveNoteToSubject moveNoteToSubject,
  }) : _moveNoteToSubject = moveNoteToSubject,
       _getNotes = getNotes,
       _createNote = createNote,
       _deleteNote = deleteNote,
       _deleteAllNotes = deleteAllNotes,
       _updateNote = updateNote,
       _attachmentRepository = attachmentRepository,
       _attachmentStorage = attachmentStorage,
       _summarizeNote = summarizeNote;

  Future<void> moveNoteToSubject(int noteId, int newSubjectId) {
    return _moveNoteToSubject(noteId, newSubjectId);
  }

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

  Future<void> updateNote(Note note, String content) async {
    final cleaned = content.trim();

    if (cleaned.isEmpty) {
      throw ArgumentError('Note content cannot be empty.');
    }

    final updatedNote = note.copyWith(
      content: cleaned,
      updatedAt: DateTime.now(),
      isEdited: true,
    );

    final success = await _updateNote(updatedNote);

    if (!success) {
      throw StateError('Failed to update note.');
    }
  }

  Future<void> _saveAttachment({
    required int noteId,
    required File file,
  }) async {
    final originalName = file.uri.pathSegments.last;

    final extension = originalName.contains('.')
        ? originalName.split('.').last.toLowerCase()
        : '';

    final isImage = const [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
    ].contains(extension);

    final isAudio = const [
      'm4a',
      'mp3',
      'wav',
      'aac',
      'ogg',
      'opus',
      'webm',
      'mp4',
    ].contains(extension);

    final storedPath = isImage
        ? await _attachmentStorage.saveImage(
            source: file,
            fileName: originalName,
          )
        : isAudio
        ? await _attachmentStorage.saveAudio(
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
      type: isImage
          ? 'image'
          : isAudio
          ? 'audio'
          : 'file',
      name: originalName,
      path: storedPath,
      mimeType: isImage
          ? 'image/$extension'
          : isAudio
          ? _audioMimeType(extension)
          : null,
      sizeBytes: await _attachmentStorage.getFileSize(storedPath),
      createdAt: DateTime.now(),
    );

    await _attachmentRepository.createAttachment(attachment);
  }

  String? _audioMimeType(String extension) {
    switch (extension) {
      case 'm4a':
        return 'audio/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'opus':
        return 'audio/opus';
      case 'webm':
        return 'audio/webm';
      case 'mp4':
        return 'audio/mp4';
      default:
        return null;
    }
  }

  Future<void> deleteNote(int id) async {
    final attachments = await _attachmentRepository.getAttachmentsForNote(id);

    for (final attachment in attachments) {
      await _attachmentStorage.deleteFile(attachment.path);
      await _attachmentRepository.deleteAttachment(attachment.id);
    }

    await _deleteNote(id);
  }

  Future<void> deleteAllNotes() async {
    final notes = await _getNotes(subjectId).first;

    for (final note in notes) {
      final attachments = await _attachmentRepository.getAttachmentsForNote(
        note.id,
      );

      for (final attachment in attachments) {
        await _attachmentStorage.deleteFile(attachment.path);
        await _attachmentRepository.deleteAttachment(attachment.id);
      }
    }

    await _deleteAllNotes(subjectId);
  }

  Future<String> summarizeNote(String content) {
    return _summarizeNote(content);
  }
}
