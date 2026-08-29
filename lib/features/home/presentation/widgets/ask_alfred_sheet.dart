import 'package:alfred/features/assistant/presentation/controllers/assistant_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../assistant/domain/entities/assistant_intent.dart';

import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/presentation/controllers/attendance_providers.dart';

import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/controllers/events_providers.dart';

import '../../../marks/domain/entities/mark.dart';
import '../../../marks/domain/entities/mark_component.dart';
import '../../../marks/presentation/controllers/marks_providers.dart';

import '../../../notes/presentation/controllers/notes_controller.dart';
import '../../../notes/presentation/controllers/notes_providers.dart';

import '../../../subjects/domain/entities/subject.dart';
import '../../../subjects/presentation/controllers/subjects_controller.dart';
import '../../../subjects/presentation/controllers/subjects_providers.dart';

import '../../../timetable/domain/entities/class_schedule.dart';
import '../../../timetable/presentation/controllers/timetable_providers.dart';

enum _Step { prompt, thinking, confirmNoteText, confirmWrite, answer }

class AskAlfredSheet extends ConsumerStatefulWidget {
  const AskAlfredSheet({super.key});

  @override
  ConsumerState<AskAlfredSheet> createState() => _AskAlfredSheetState();
}

class _AskAlfredSheetState extends ConsumerState<AskAlfredSheet> {
  final _promptController = TextEditingController();
  final _contentController = TextEditingController();

  _Step _step = _Step.prompt;
  String? _errorText;
  String? _answerText;

  Subject? _selectedSubject; // used by the note-confirm step
  AssistantIntent? _pendingIntent; // used by the generic confirm step
  Subject? _pendingSubject;

  DateTime? _lastRequestAt;

  bool get _isCoolingDown {
    if (_lastRequestAt == null) return false;
    return DateTime.now().difference(_lastRequestAt!) <
        const Duration(seconds: 13);
  }

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechInitialized = false;
@override
void dispose() {
  _speech.stop();
  _promptController.dispose();
  _contentController.dispose();
  super.dispose();
}

Future<void> _toggleListening() async {
  if (_isListening) {
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
    return;
  }

  if (!_speechInitialized) {
    _speechInitialized = await _speech.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
  }

  if (!_speechInitialized) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Speech recognition isn't available on this device.")),
    );
    return;
  }

  setState(() => _isListening = true);

  await _speech.listen(
    onResult: (result) {
      setState(() {
        _promptController.text = result.recognizedWords;
        _promptController.selection =
            TextSelection.collapsed(offset: _promptController.text.length);
      });
    },
  );
}
  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsControllerProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: subjectsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to load subjects: $e'),
        ),
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Add a subject first, then Alfred can help with it.'),
            );
          }

          switch (_step) {
            case _Step.prompt:
              return _buildPromptStep(subjects);
            case _Step.thinking:
              return _buildThinkingStep();
            case _Step.confirmNoteText:
              return _buildConfirmNoteStep(subjects);
            case _Step.confirmWrite:
              return _buildConfirmWriteStep();
            case _Step.answer:
              return _buildAnswerStep();
          }
        },
      ),
    );
  }

  // ================= STEP: prompt =================

  Widget _buildPromptStep(List<Subject> subjects) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ask Alfred',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Try: "Add note to Physics: quiz is Friday"\n'
          'or: "Mark me present in Physics today"\n'
          'or: "How am I doing in Chemistry?"',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
   TextField(
  controller: _promptController,
  autofocus: true,
  minLines: 2,
  maxLines: 4,
  textCapitalization: TextCapitalization.sentences,
  decoration: InputDecoration(
    hintText: _isListening ? 'Listening…' : 'Type or speak to Alfred…',
    border: const OutlineInputBorder(),
    errorText: _errorText,
    suffixIcon: IconButton(
      icon: Icon(
        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
        color: _isListening ? Theme.of(context).colorScheme.error : null,
      ),
      onPressed: _toggleListening,
    ),
  ),
),     const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isCoolingDown ? null : () => _handlePrompt(subjects),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(_isCoolingDown ? 'Please wait…' : 'Send to Alfred'),
          ),
        ),
      ],
    );
  }

  Widget _buildThinkingStep() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Thinking…'),
          ],
        ),
      ),
    );
  }

  // ================= STEP: note-specific confirm (create only) =================

  Widget _buildConfirmNoteStep(List<Subject> subjects) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Save this note?',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Subject>(
          initialValue: _selectedSubject,
          decoration: const InputDecoration(
            labelText: 'Subject',
            border: OutlineInputBorder(),
          ),
          items: subjects
              .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
              .toList(),
          onChanged: (value) => setState(() => _selectedSubject = value),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _contentController,
          minLines: 2,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Note content',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = _Step.prompt),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _selectedSubject == null ? null : _handleConfirmNote,
                child: const Text('Add note'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= STEP: generic confirm (everything else) =================

  Widget _buildConfirmWriteStep() {
    final intent = _pendingIntent;
    final subject = _pendingSubject;

    if (intent == null || subject == null) {
      // Shouldn't happen, but fail safe back to prompt instead of crashing.
      return _buildPromptStep(const []);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm action',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        _summaryRow('Subject', subject.name),
        _summaryRow('Module', intent.module.name),
        _summaryRow('Action', intent.operation.name),
        ...intent.fields.entries.map((e) => _summaryRow(e.key, '${e.value}')),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = _Step.prompt),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _handleConfirmWrite,
                child: const Text('Confirm'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  // ================= STEP: answer (read path) =================

  Widget _buildAnswerStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              'Alfred says',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(child: Text(_answerText ?? '')),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => setState(() {
              _step = _Step.prompt;
              _answerText = null;
              _promptController.clear();
            }),
            child: const Text('Ask something else'),
          ),
        ),
      ],
    );
  }

  // ================= LOGIC: dispatch =================

  Future<void> _handlePrompt(List<Subject> subjects) async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    if (_isCoolingDown) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Give Alfred a moment before asking again.'),
        ),
      );
      return;
    }

    _lastRequestAt = DateTime.now(); // <-- mark the request as starting

    setState(() {
      _errorText = null;
      _step = _Step.thinking;
    });

    try {
      final parser = ref.read(parseAssistantPromptProvider);
      final intent = await parser(
        prompt: prompt,
        subjectNames: subjects.map((s) => s.name).toList(),
      );

      final matched = _matchSubject(intent.subjectName, subjects);

      if (intent.module == AssistantModule.unknown ||
          intent.operation == AssistantOperation.unknown) {
        setState(() => _step = _Step.prompt);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Alfred didn't understand that — try rephrasing."),
          ),
        );
        return;
      }

      if (intent.operation == AssistantOperation.query) {
        await _handleQuery(intent, matched, subjects);
        return;
      }

      // Notes create keeps its own editable-text confirm screen.
      if (intent.module == AssistantModule.notes &&
          intent.operation == AssistantOperation.create) {
        setState(() {
          _selectedSubject = matched ?? subjects.first;
          _contentController.text =
              (intent.fields['content'] as String?) ?? prompt;
          _step = _Step.confirmNoteText;
        });
        return;
      }

      // Everything else: generic summary confirm.
      setState(() {
        _pendingIntent = intent;
        _pendingSubject = matched ?? subjects.first;
        _step = _Step.confirmWrite;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _step = _Step.prompt);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Alfred hit an error: $e')));
    }
  }

  Future<void> _handleQuery(
    AssistantIntent intent,
    Subject? matched,
    List<Subject> subjects,
  ) async {
    switch (intent.module) {
      case AssistantModule.notes:
        await _handleQueryNotes(intent, matched, subjects);
        break;
      case AssistantModule.marks:
        await _handleQueryMarks(intent, matched, subjects);
        break;
      case AssistantModule.events:
        await _handleQueryEvents(intent, matched, subjects);
        break;
      case AssistantModule.attendance:
        await _handleQueryAttendance(intent, matched, subjects);
        break;
      case AssistantModule.timetable:
        await _handleQueryTimetable(intent, matched, subjects);
        break;
      case AssistantModule.subjects:
      case AssistantModule.unknown:
        if (!mounted) return;
        setState(() => _step = _Step.prompt);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Alfred can't answer that kind of question yet."),
          ),
        );
        break;
    }
  }

  Future<void> _handleQueryNotes(
    AssistantIntent intent,
    Subject? matched,
    List<Subject> subjects,
  ) async {
    final subject = matched ?? subjects.first;
    final notes = await ref.read(getNotesProvider)(subject.id).first;

    final answer = await ref.read(answerFromNotesProvider)(
      question: intent.question ?? _promptController.text.trim(),
      subjectName: subject.name,
      notes: notes,
    );

    if (!mounted) return;
    setState(() {
      _answerText = answer;
      _step = _Step.answer;
    });
  }

  Future<void> _handleQueryMarks(
    AssistantIntent intent,
    Subject? matched,
    List<Subject> subjects,
  ) async {
    final subject = matched ?? subjects.first;
    final components = await ref.read(
      subjectMarkComponentsProvider(subject.id).future,
    );
    final marks = await ref.read(subjectMarksProvider(subject.id).future);

    final answer = await ref.read(answerFromMarksProvider)(
      question: intent.question ?? _promptController.text.trim(),
      subjectName: subject.name,
      components: components,
      marks: marks,
    );

    if (!mounted) return;
    setState(() {
      _answerText = answer;
      _step = _Step.answer;
    });
  }

  Future<void> _handleQueryEvents(
    AssistantIntent intent,
    Subject? matched,
    List<Subject> subjects,
  ) async {
    final subject = matched ?? subjects.first;
    final events = await ref.read(subjectEventsProvider(subject.id).future);

    final answer = await ref.read(answerFromEventsProvider)(
      question: intent.question ?? _promptController.text.trim(),
      subjectName: subject.name,
      events: events,
    );

    if (!mounted) return;
    setState(() {
      _answerText = answer;
      _step = _Step.answer;
    });
  }

  Future<void> _handleQueryAttendance(
    AssistantIntent intent,
    Subject? matched,
    List<Subject> subjects,
  ) async {
    final subject = matched ?? subjects.first;
    final records = await ref.read(
      attendanceForSubjectProvider(subject.id).future,
    );

    final answer = await ref.read(answerFromAttendanceProvider)(
      question: intent.question ?? _promptController.text.trim(),
      subjectName: subject.name,
      records: records,
    );

    if (!mounted) return;
    setState(() {
      _answerText = answer;
      _step = _Step.answer;
    });
  }

  Future<void> _handleQueryTimetable(
    AssistantIntent intent,
    Subject? matched,
    List<Subject> subjects,
  ) async {
    final subject = matched ?? subjects.first;
    final allSchedules = await ref.read(allTimetableProvider.future);
    final subjectSchedules = allSchedules
        .where((s) => s.subjectId == subject.id)
        .toList();

    final answer = await ref.read(answerFromTimetableProvider)(
      question: intent.question ?? _promptController.text.trim(),
      subjectName: subject.name,
      schedules: subjectSchedules,
    );

    if (!mounted) return;
    setState(() {
      _answerText = answer;
      _step = _Step.answer;
    });
  }

  // ================= LOGIC: note create (dedicated flow) =================

  Future<void> _handleConfirmNote() async {
    final subject = _selectedSubject;
    final content = _contentController.text.trim();
    if (subject == null || content.isEmpty) return;

    setState(() => _step = _Step.thinking);

    try {
      final controller = ref.read(notesControllerProvider(subject.id));
      await controller.createTextNote(content);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added to ${subject.name}')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _step = _Step.confirmNoteText);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save note: $e')));
    }
  }

  // ================= LOGIC: generic write dispatch =================

  Future<void> _handleConfirmWrite() async {
    final intent = _pendingIntent;
    final subject = _pendingSubject;
    if (intent == null || subject == null) return;

    setState(() => _step = _Step.thinking);

    try {
      switch (intent.module) {
        case AssistantModule.attendance:
          await _executeAttendance(intent, subject);
          break;
        case AssistantModule.events:
          await _executeEvents(intent, subject);
          break;
        case AssistantModule.marks:
          await _executeMarks(intent, subject);
          break;
        case AssistantModule.subjects:
          await _executeSubjects(intent, subject);
          break;
        case AssistantModule.timetable:
          await _executeTimetable(intent, subject);
          break;
        case AssistantModule.notes:
          if (intent.operation == AssistantOperation.delete) {
            await _executeNotesDelete(intent, subject);
          } else {
            throw UnsupportedError(
              'Notes only supports create and delete right now.',
            );
          }
          break;
        case AssistantModule.unknown:
          throw UnsupportedError('Unrecognized module.');
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Done')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _step = _Step.confirmWrite);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  // ---------------- Attendance ----------------

  Future<void> _executeAttendance(
    AssistantIntent intent,
    Subject subject,
  ) async {
    final dateStr = intent.fields['date'] as String?;
    final date = dateStr == null ? DateTime.now() : DateTime.parse(dateStr);

    if (intent.operation == AssistantOperation.delete) {
      final existing = await ref
          .read(attendanceRepositoryProvider)
          .getBySubjectAndDate(subject.id, date);
      if (existing == null)
        throw StateError('No attendance record found for that date.');
      await ref.read(deleteAttendanceProvider)(existing.id);
      return;
    }

    final record = AttendanceRecord(
      id: 0,
      subjectId: subject.id,
      date: date,
      present: intent.fields['present'] == true,
      markedAt: DateTime.now(),
      note: intent.fields['note'] as String?,
    );
    await ref.read(createAttendanceProvider)(record); // upserts internally
  }

  // ---------------- Events ----------------

  Future<void> _executeEvents(AssistantIntent intent, Subject subject) async {
    if (intent.operation == AssistantOperation.create) {
      final event = Event(
        id: 0,
        subjectId: subject.id,
        title: intent.fields['title'] as String,
        description: intent.fields['description'] as String?,
        type: (intent.fields['type'] as String?) ?? 'task',
        priority: (intent.fields['priority'] as String?) ?? 'medium',
        dueDate: DateTime.parse(intent.fields['dueDate'] as String),
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ref.read(createEventProvider)(event);
      return;
    }

    final events = await ref.read(subjectEventsProvider(subject.id).future);
    final match = _matchByText(
      events,
      intent.fields['titleMatch'] as String?,
      (e) => e.title,
    );
    if (match == null) throw StateError('Could not find a matching event.');

    if (intent.operation == AssistantOperation.delete) {
      await ref.read(deleteEventProvider)(match.id);
      return;
    }

    final updated = match.copyWith(
      title: intent.fields['title'] as String?,
      priority: intent.fields['priority'] as String?,
      dueDate: intent.fields['dueDate'] != null
          ? DateTime.parse(intent.fields['dueDate'] as String)
          : null,
      isCompleted: intent.fields['isCompleted'] as bool?,
      updatedAt: DateTime.now(),
    );
    await ref.read(updateEventProvider)(updated);
  }

  // ---------------- Marks ----------------

  Future<void> _executeMarks(AssistantIntent intent, Subject subject) async {
    final components = await ref.read(
      subjectMarkComponentsProvider(subject.id).future,
    );

    if (intent.operation == AssistantOperation.create) {
      final component = MarkComponent(
        id: 0,
        subjectId: subject.id,
        name: intent.fields['componentName'] as String,
        type: intent.fields['type'] as String?,
        maxMarks: (intent.fields['maxMarks'] as num).toDouble(),
        sortOrder: components.length,
        createdAt: DateTime.now(),
      );
      await ref.read(createMarkComponentProvider)(component);
      return;
    }

    final match = _matchByText(
      components,
      intent.fields['componentNameMatch'] as String?,
      (c) => c.name,
    );
    if (match == null)
      throw StateError('Could not find a matching assessment.');

    if (intent.operation == AssistantOperation.delete) {
      await ref.read(deleteMarkComponentProvider)(match.id);
      return;
    }

    final marks = await ref.read(subjectMarksProvider(subject.id).future);
    Mark? existing;
    for (final m in marks) {
      if (m.componentId == match.id) {
        existing = m;
        break;
      }
    }

    final mark = Mark(
      id: existing?.id ?? 0,
      subjectId: subject.id,
      componentId: match.id,
      obtainedMarks: (intent.fields['obtainedMarks'] as num).toDouble(),
      updatedAt: DateTime.now(),
    );
    await ref.read(saveMarkProvider)(mark);
  }

  // ---------------- Subjects ----------------

  Future<void> _executeSubjects(AssistantIntent intent, Subject subject) async {
    if (intent.operation == AssistantOperation.delete) {
      await ref.read(deleteSubjectProvider)(subject.id);
      return;
    }

    if (intent.operation == AssistantOperation.create) {
      await ref
          .read(subjectsControllerProvider.notifier)
          .createSubject(
            name: intent.fields['name'] as String,
            code: intent.fields['code'] as String?,
            instructor: intent.fields['instructor'] as String?,
            room: intent.fields['room'] as String?,
          );
      return;
    }

    final updated = subject.copyWith(
      name: intent.fields['name'] as String?,
      code: intent.fields['code'] as String?,
      instructor: intent.fields['instructor'] as String?,
      room: intent.fields['room'] as String?,
      updatedAt: DateTime.now(),
    );
    await ref.read(updateSubjectProvider)(updated);
  }

  // ---------------- Timetable ----------------

  Future<void> _executeTimetable(
    AssistantIntent intent,
    Subject subject,
  ) async {
    if (intent.operation == AssistantOperation.create) {
      final schedule = ClassSchedule(
        id: 0,
        subjectId: subject.id,
        weekday: intent.fields['weekday'] as int,
        startTime: intent.fields['startTime'] as String,
        endTime: intent.fields['endTime'] as String,
        room: intent.fields['room'] as String?,
        teacher: intent.fields['teacher'] as String?,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ref.read(createScheduleProvider)(schedule);
      return;
    }

    final all = await ref.read(allTimetableProvider.future);
    ClassSchedule? match;
    for (final s in all) {
      if (s.subjectId == subject.id &&
          s.weekday == intent.fields['weekdayMatch'] &&
          s.startTime == intent.fields['startTimeMatch']) {
        match = s;
        break;
      }
    }
    if (match == null) throw StateError('Could not find a matching class.');

    if (intent.operation == AssistantOperation.delete) {
      await ref.read(deleteScheduleProvider)(match.id);
      return;
    }

    final updated = match.copyWith(
      startTime: intent.fields['startTime'] as String?,
      endTime: intent.fields['endTime'] as String?,
      room: intent.fields['room'] as String?,
      updatedAt: DateTime.now(),
    );
    await ref.read(updateScheduleProvider)(updated);
  }

  // ---------------- Notes (delete only) ----------------

  Future<void> _executeNotesDelete(
    AssistantIntent intent,
    Subject subject,
  ) async {
    final notes = await ref.read(getNotesProvider)(subject.id).first;
    final match = _matchByText(
      notes,
      intent.fields['contentMatch'] as String?,
      (n) => n.content,
    );
    if (match == null) throw StateError('Could not find a matching note.');
    await ref.read(notesControllerProvider(subject.id)).deleteNote(match.id);
  }

  // ================= Helpers =================

  Subject? _matchSubject(String? name, List<Subject> subjects) {
    if (name == null || name.trim().isEmpty) return null;
    final target = name.trim().toLowerCase();

    for (final s in subjects) {
      if (s.name.toLowerCase() == target) return s;
    }
    for (final s in subjects) {
      if (s.name.toLowerCase().contains(target) ||
          target.contains(s.name.toLowerCase())) {
        return s;
      }
    }
    return null;
  }

  T? _matchByText<T>(List<T> items, String? query, String Function(T) getText) {
    if (query == null || query.trim().isEmpty) return null;
    final target = query.trim().toLowerCase();
    for (final item in items) {
      if (getText(item).toLowerCase().contains(target)) return item;
    }
    return null;
  }
}
