import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/ai_providers.dart';
import '../../../../core/database/daos/notes_dao.dart';
import '../../../../core/database/database_providers.dart';
import '../../data/datasources/notes_local_datasource.dart';
import '../../data/repositories/notes_repository_impl.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../domain/usecases/create_note.dart';
import '../../domain/usecases/delete_note.dart';
import '../../domain/usecases/get_note.dart';
import '../../domain/usecases/get_notes.dart';

import '../../domain/usecases/summarize_note.dart';

import '../../domain/usecases/parse_note_prompt.dart';
final notesDaoProvider = Provider<NotesDao>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return NotesDao(database);
});

final notesLocalDataSourceProvider =
    Provider<NotesLocalDataSource>((ref) {
  return NotesLocalDataSource(
    ref.watch(notesDaoProvider),
  );
});

final notesRepositoryProvider =
    Provider<NotesRepository>((ref) {
  return NotesRepositoryImpl(
    ref.watch(notesLocalDataSourceProvider),
  );
});

final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(
    ref.watch(notesRepositoryProvider),
  );
});

final getNoteProvider = Provider<GetNote>((ref) {
  return GetNote(
    ref.watch(notesRepositoryProvider),
  );
});

final createNoteProvider = Provider<CreateNote>((ref) {
  return CreateNote(
    ref.watch(notesRepositoryProvider),
  );
});

final deleteNoteProvider = Provider<DeleteNote>((ref) {
  return DeleteNote(
    ref.watch(notesRepositoryProvider),
  );
});


final summarizeNoteProvider = Provider<SummarizeNote>((ref) {
  return SummarizeNote(ref.watch(geminiClientProvider));
});


final parseNotePromptProvider = Provider<ParseNotePrompt>((ref) {
  return ParseNotePrompt(ref.watch(geminiClientProvider));
});