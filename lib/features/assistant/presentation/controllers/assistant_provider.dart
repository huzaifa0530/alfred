import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/ai_providers.dart';

import '../../domain/usecases/answer_from_attendance.dart';
import '../../domain/usecases/answer_from_events.dart';
import '../../domain/usecases/answer_from_marks.dart';
import '../../domain/usecases/answer_from_notes.dart';
import '../../domain/usecases/answer_from_timetable.dart';
import '../../domain/usecases/parse_assistant_prompt.dart';
import '../../domain/usecases/answer_general.dart';


final parseAssistantPromptProvider = Provider<ParseAssistantPrompt>((ref) {
  return ParseAssistantPrompt(ref.watch(geminiClientProvider));
});

final answerFromNotesProvider = Provider<AnswerFromNotes>((ref) {
  return AnswerFromNotes(ref.watch(geminiClientProvider));
});

final answerFromMarksProvider = Provider<AnswerFromMarks>((ref) {
  return AnswerFromMarks(ref.watch(geminiClientProvider));
});

final answerFromTimetableProvider = Provider<AnswerFromTimetable>((ref) {
  return AnswerFromTimetable(ref.watch(geminiClientProvider));
});

final answerFromEventsProvider = Provider<AnswerFromEvents>((ref) {
  return AnswerFromEvents(ref.watch(geminiClientProvider));
});

final answerFromAttendanceProvider = Provider<AnswerFromAttendance>((ref) {
  return AnswerFromAttendance(ref.watch(geminiClientProvider));
});
final answerGeneralProvider = Provider<AnswerGeneral>((ref) {
  return AnswerGeneral(ref.watch(geminiClientProvider));
});
