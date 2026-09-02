import 'package:alfred/app/theme/app_text_styles.dart';
import 'package:alfred/core/notifications/notification_service.dart';
import 'package:alfred/core/notifications/recurring_alarm_service.dart';
import 'package:alfred/core/utils/scheduletime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/utils/timeout.dart';

import '../../../assistant/domain/entities/assistant_intent.dart';
import '../../../assistant/presentation/controllers/assistant_provider.dart';

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

  Subject? _selectedSubject; // used only by the dedicated single-note flow

  // The orchestrator's working state for a confirmed multi-step batch.
  List<AssistantIntent> _pendingIntents = [];
  List<Subject> _knownSubjects = []; // grows as subjects are created mid-batch

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
        const SnackBar(
          content: Text("Speech recognition isn't available on this device."),
        ),
      );
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _promptController.text = result.recognizedWords;
          _promptController.selection = TextSelection.collapsed(
            offset: _promptController.text.length,
          );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ask Alfred',
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'What can I do for you, sir?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 14),

        Text(
          'For example',
          style: AppTextStyles.labelSmall.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          '"Create a Design subject, add a note saying hello, '
          'and schedule a quiz for it."',
          style: AppTextStyles.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),

        const SizedBox(height: 18),

        TextField(
          controller: _promptController,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: AppTextStyles.bodyMedium.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: _isListening
                ? 'Listening for your command…'
                : 'Tell Alfred what you need…',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.error, width: 1.5),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainer.withValues(alpha: 0.55),
            errorText: _errorText,
            suffixIcon: IconButton(
              tooltip: _isListening ? 'Stop listening' : 'Speak to Alfred',
              icon: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _isListening ? colorScheme.error : colorScheme.primary,
              ),
              onPressed: _toggleListening,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isCoolingDown ? null : () => _handlePrompt(subjects),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(
              _isCoolingDown ? 'Please wait…' : 'Give Alfred the command',
              style: AppTextStyles.labelLarge,
            ),
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

  // ================= STEP: single-note confirm (only used when the whole prompt is one note) =================

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
                onPressed: _selectedSubject == null
                    ? null
                    : _handleConfirmSingleNote,
                child: const Text('Add note'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= STEP: orchestrated batch confirm =================

  Widget _buildConfirmWriteStep() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _pendingIntents.length > 1
                ? 'Confirm these ${_pendingIntents.length} actions'
                : 'Confirm this action',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 6),

          if (_pendingIntents.length > 1)
            Text(
              "Alfred will carry these out in order — a subject created in an "
              "earlier step is available to the steps after it.",
              style: Theme.of(context).textTheme.bodySmall,
            ),

          const SizedBox(height: 14),

          // Scrollable action list
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (var i = 0; i < _pendingIntents.length; i++) ...[
                  _summaryRow('Step', '${i + 1}'),
                  _summaryRow(
                    'Subject',
                    _pendingIntents[i].subjectName ?? '(resolved at run time)',
                  ),
                  _summaryRow('Module', _pendingIntents[i].module.name),
                  _summaryRow('Action', _pendingIntents[i].operation.name),

                  ..._pendingIntents[i].fields.entries.map(
                    (e) => _summaryRow(e.key, '${e.value}'),
                  ),

                  if (i != _pendingIntents.length - 1)
                    const Divider(height: 24),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Always visible
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _step = _Step.prompt);
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _handleConfirmWrite,
                  child: Text(
                    _pendingIntents.length > 1 ? 'Confirm All' : 'Confirm',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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

  // ================= STEP: answer (query results / batch results) =================

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

  // ================= LOGIC: parse & plan =================

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
    _lastRequestAt = DateTime.now();

    setState(() {
      _errorText = null;
      _step = _Step.thinking;
    });

    try {
      final parser = ref.read(parseAssistantPromptProvider);
      final intents =
          await parser(
            prompt: prompt,
            subjectNames: subjects.map((s) => s.name).toList(),
          ).timeout(
            const Duration(seconds: 25),
            onTimeout: () => throw StateError(
              "Alfred is taking too long to think — try a shorter or simpler request.",
            ),
          );
      if (intents.isEmpty) {
        throw StateError("Alfred couldn't make sense of that.");
      }

      // Single-item shortcut: a lone note-create keeps the friendlier
      // editable-text confirm screen instead of the generic batch view.
      if (intents.length == 1 &&
          intents.first.module == AssistantModule.notes &&
          intents.first.operation == AssistantOperation.create) {
        final matched = _matchSubject(intents.first.subjectName, subjects);
        setState(() {
          _selectedSubject =
              matched ?? (subjects.isNotEmpty ? subjects.first : null);
          _contentController.text =
              (intents.first.fields['content'] as String?) ?? prompt;
          _step = _Step.confirmNoteText;
        });
        return;
      }

      // Separate the batch into: things answered immediately (queries,
      // general chat, unrecognized) vs. things that need confirmation
      // before writing to the database.
      final answers = <String>[];
      final pendingWrites = <AssistantIntent>[];

      for (final intent in intents) {
        if (intent.module == AssistantModule.general) {
          final answerer = ref.read(answerGeneralProvider);
          answers.add(await answerer(intent.question ?? prompt));
          continue;
        }

        if (intent.module == AssistantModule.unknown ||
            intent.operation == AssistantOperation.unknown) {
          answers.add("I'm afraid that one escapes me, sir.");
          continue;
        }

        if (intent.operation == AssistantOperation.query) {
          final matched = _matchSubject(intent.subjectName, subjects);
          answers.add(await _resolveQuery(intent, matched, subjects));
          continue;
        }

        pendingWrites.add(intent);
      }

      if (pendingWrites.isNotEmpty) {
        setState(() {
          _pendingIntents = pendingWrites;
          _knownSubjects = List.of(
            subjects,
          ); // orchestrator's live view of subjects
          _step = _Step.confirmWrite;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _answerText = answers.join('\n\n');
        _step = _Step.answer;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _step = _Step.prompt);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Alfred hit an error: $e')));
    }
  }

  // ================= LOGIC: query resolution (read-only, returns text) =================

  Future<String> _resolveQuery(
    AssistantIntent intent,
    Subject? matched,
    List<Subject> subjects,
  ) async {
    switch (intent.module) {
      case AssistantModule.notes:
        {
          final subject =
              matched ?? (subjects.isNotEmpty ? subjects.first : null);
          if (subject == null)
            return "There are no subjects to check yet, sir.";
          final notes = await ref.read(getNotesProvider)(subject.id).first;
          return withTimeout(
            ref.read(answerFromNotesProvider)(
              question: intent.question ?? _promptController.text.trim(),
              subjectName: subject.name,
              notes: notes,
            ),
          );
        }

      case AssistantModule.marks:
        {
          final subject =
              matched ?? (subjects.isNotEmpty ? subjects.first : null);
          if (subject == null)
            return "There are no subjects to check yet, sir.";
          final components = await ref.read(
            subjectMarkComponentsProvider(subject.id).future,
          );
          final marks = await ref.read(subjectMarksProvider(subject.id).future);
          return ref.read(answerFromMarksProvider)(
            question: intent.question ?? _promptController.text.trim(),
            subjectName: subject.name,
            components: components,
            marks: marks,
          );
        }

      case AssistantModule.events:
        {
          final subject =
              matched ?? (subjects.isNotEmpty ? subjects.first : null);
          if (subject == null)
            return "There are no subjects to check yet, sir.";
          final events = await ref.read(
            subjectEventsProvider(subject.id).future,
          );
          return ref.read(answerFromEventsProvider)(
            question: intent.question ?? _promptController.text.trim(),
            subjectName: subject.name,
            events: events,
          );
        }

      case AssistantModule.attendance:
        {
          final subject =
              matched ?? (subjects.isNotEmpty ? subjects.first : null);
          if (subject == null)
            return "There are no subjects to check yet, sir.";
          final records = await ref.read(
            attendanceForSubjectProvider(subject.id).future,
          );
          return ref.read(answerFromAttendanceProvider)(
            question: intent.question ?? _promptController.text.trim(),
            subjectName: subject.name,
            records: records,
          );
        }

      case AssistantModule.timetable:
        return _resolveTimetableQuery(intent, matched, subjects);

      case AssistantModule.focusAlarm:
        return "Focus check-ins aren't something I can report on — try asking me to start or stop one instead.";
      case AssistantModule.subjects:
      case AssistantModule.general:
      case AssistantModule.unknown:
        return "I can't answer that kind of question yet, sir.";
    }
  }

  Future<String> _resolveTimetableQuery(
    AssistantIntent intent,
    Subject? matched,
    List<Subject> subjects,
  ) async {
    final all = await ref
        .read(timetableSnapshotProvider.future)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () =>
              throw StateError('Could not read the timetable in time.'),
        );

    List<ClassSchedule> relevant = matched != null
        ? all.where((s) => s.subjectId == matched.id).toList()
        : all;

    final dayField = intent.fields['day'] as String?;
    if (dayField != null) {
      int? targetWeekday;
      if (dayField.toLowerCase() == 'today') {
        targetWeekday = DateTime.now().weekday;
      } else if (dayField.toLowerCase() == 'tomorrow') {
        targetWeekday = DateTime.now().add(const Duration(days: 1)).weekday;
      } else {
        try {
          targetWeekday = DateTime.parse(dayField).weekday;
        } catch (_) {}
      }
      if (targetWeekday != null) {
        relevant = relevant.where((s) => s.weekday == targetWeekday).toList();
      }
    }

    final subjectLabel = matched?.name ?? 'all subjects';
    final namesById = {for (final s in subjects) s.id: s.name};

    return ref.read(answerFromTimetableProvider)(
      question: intent.question ?? _promptController.text.trim(),
      subjectName: subjectLabel,
      schedules: relevant,
      subjectNamesById: namesById,
    );
  }
  // ================= LOGIC: single-note dedicated flow =================

  Future<void> _handleConfirmSingleNote() async {
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

  // ================= LOGIC: the orchestrator =================
  //
  // Walks _pendingIntents in order. Each step resolves its subject against
  // _knownSubjects, which starts as a snapshot of existing subjects and
  // grows every time a "create subject" step succeeds — so later steps in
  // the same prompt can reference a subject that didn't exist when the
  // batch was planned. Steps are independent of each other unless they
  // happen to share a subject name, in which case order matters naturally:
  // create it before you reference it.

  Future<void> _handleConfirmWrite() async {
    setState(() => _step = _Step.thinking);

    final results = <String>[];

    for (final intent in _pendingIntents) {
      try {
        if (intent.module == AssistantModule.subjects &&
            intent.operation == AssistantOperation.create) {
          final createdName = intent.fields['name'] as String;
          await ref
              .read(subjectsControllerProvider.notifier)
              .createSubject(
                name: createdName,
                code: intent.fields['code'] as String?,
                instructor: intent.fields['instructor'] as String?,
                room: intent.fields['room'] as String?,
              );

          final newSubject = Subject(
            id: 0,
            name: createdName,
            code: intent.fields['code'] as String?,
            instructor: intent.fields['instructor'] as String?,
            room: intent.fields['room'] as String?,
            color: null,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          _knownSubjects = [..._knownSubjects, newSubject];
          results.add('✓ created subject "$createdName"');
          continue;
        }

        final subject =
            _matchSubject(intent.subjectName, _knownSubjects) ??
            (_knownSubjects.isNotEmpty ? _knownSubjects.first : null);

        if (subject == null) {
          results.add(
            '✗ ${intent.module.name} ${intent.operation.name}: no subject available',
          );
          continue;
        }

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
            await _executeSubjects(intent, subject); // update/delete only
            break;
          case AssistantModule.timetable:
            await _executeTimetable(intent, subject);
            break;
          case AssistantModule.notes:
            if (intent.operation == AssistantOperation.create) {
              await _executeNotesCreate(intent, subject);
            } else if (intent.operation == AssistantOperation.delete) {
              await _executeNotesDelete(intent, subject);
            } else {
              throw UnsupportedError('Notes only supports create and delete.');
            }
            break;
          case AssistantModule.focusAlarm:
            final service = RecurringAlarmService();
            if (intent.operation == AssistantOperation.delete) {
              await service.stop();
            } else {
              final minutes =
                  (intent.fields['intervalMinutes'] as num?)?.toInt() ?? 20;
              await service.start(minutes);
            }
            break;
          case AssistantModule.general:
          case AssistantModule.unknown:
            throw UnsupportedError('Unrecognized action.');
        }

        results.add(
          '✓ ${intent.module.name} ${intent.operation.name} for ${subject.name}',
        );
      } catch (e) {
        results.add(
          '✗ ${intent.module.name} ${intent.operation.name} failed: $e',
        );
      }
    }

    if (!mounted) return;

    final anyFailed = results.any((r) => r.startsWith('✗'));
    if (!anyFailed) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Consider it done.')));
    } else {
      setState(() {
        _answerText = results.join('\n');
        _step = _Step.answer;
      });
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
      present: _asBool(intent.fields['present']) ?? false,
      markedAt: DateTime.now(),
      note: intent.fields['note'] as String?,
    );
    await ref.read(createAttendanceProvider)(record); // upserts internally
  }

  DateTime _parseDueDateTime(Map<String, dynamic> fields) {
    final dateStr = fields['dueDate'] as String;
    final timeStr = fields['dueTime'] as String?;

    final date = DateTime.parse(dateStr);

    if (timeStr != null && timeStr.trim().isNotEmpty) {
      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 23;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 59) : 59;
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    // No specific time mentioned — default to end of that day, not midnight.
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  // ---------------- Events ----------------
  Future<void> _executeEvents(AssistantIntent intent, Subject subject) async {
    if (intent.operation == AssistantOperation.create) {
      final dueDate = _parseDueDateTime(intent.fields);

      final event = Event(
        id: 0,
        subjectId: subject.id,
        title: intent.fields['title'] as String,
        description: intent.fields['description'] as String?,
        type: (intent.fields['type'] as String?) ?? 'task',
        priority: (intent.fields['priority'] as String?) ?? 'medium',
        dueDate: dueDate,
        isCompleted: _asBool(intent.fields['isCompleted']) ?? false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newId = await ref.read(createEventProvider)(event);
      return;
    }
    // One-shot read via the repository, not the live StreamProvider —
    // avoids the same cold-.future-read fragility that hung timetable.
    final events = await ref
        .read(eventsRepositoryProvider)
        .watchEventsForSubject(subject.id)
        .first
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw StateError('Could not read events in time.'),
        );

    print('EVENTS DEBUG: found ${events.length} events for ${subject.name}');
    for (final e in events) {
      print('  - "${e.title}" completed=${e.isCompleted}');
    }

    final titleMatch = intent.fields['titleMatch'] as String?;
    print('EVENTS DEBUG: titleMatch = "$titleMatch"');

    final match = _matchByText(events, titleMatch, (e) => e.title);

    if (match == null) {
      print('EVENTS DEBUG: NO MATCH FOUND');
      throw StateError('Could not find a matching event.');
    }

    print(
      'EVENTS DEBUG: matched "${match.title}", currently completed=${match.isCompleted}',
    );

    if (intent.operation == AssistantOperation.delete) {
      await ref.read(deleteEventProvider)(match.id);
      return;
    }

    final newCompleted = _asBool(intent.fields['isCompleted']);
    print('EVENTS DEBUG: newCompleted value = $newCompleted');

    final updated = match.copyWith(
      title: intent.fields['title'] as String?,
      priority: intent.fields['priority'] as String?,
      dueDate: intent.fields['dueDate'] != null
          ? DateTime.parse(intent.fields['dueDate'] as String)
          : null,
      isCompleted: newCompleted,
      updatedAt: DateTime.now(),
    );

    print('EVENTS DEBUG: after copyWith, isCompleted=${updated.isCompleted}');

    await ref.read(updateEventProvider)(updated);
    print('EVENTS DEBUG: update call completed');
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

  // ---------------- Subjects (update / delete only — create is handled inline in the orchestrator) ----------------

  Future<void> _executeSubjects(AssistantIntent intent, Subject subject) async {
    if (intent.operation == AssistantOperation.delete) {
      await ref.read(deleteSubjectProvider)(subject.id);
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
      final weekday = intent.fields['weekday'] as int;

      final startTime = normalizeScheduleTime(
        intent.fields['startTime'] as String,
      );

      final endTime = normalizeScheduleTime(
        intent.fields['endTime'] as String,
      );

      final schedule = ClassSchedule(
        id: 0,
        subjectId: subject.id,
        weekday: weekday,
        startTime: startTime,
        endTime: endTime,
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

    final weekdayMatch = intent.fields['weekdayMatch'] as int?;

    final startTimeMatch = intent.fields['startTimeMatch'] as String?;

    final normalizedStartTimeMatch = startTimeMatch == null
        ? null
        : normalizeScheduleTime(startTimeMatch);

    ClassSchedule? match;

    for (final s in all) {
      if (s.subjectId == subject.id &&
          s.weekday == weekdayMatch &&
          s.startTime == normalizedStartTimeMatch) {
        match = s;
        break;
      }
    }

    if (match == null) {
      throw StateError('Could not find a matching class.');
    }

    if (intent.operation == AssistantOperation.delete) {
      await ref.read(deleteScheduleProvider)(match.id);
      return;
    }

    final updated = match.copyWith(
      startTime: intent.fields['startTime'] == null
          ? match.startTime
          : normalizeScheduleTime(intent.fields['startTime'] as String),
      endTime: intent.fields['endTime'] == null
          ? match.endTime
          : normalizeScheduleTime(intent.fields['endTime'] as String),
      room: intent.fields['room'] as String?,
      teacher: intent.fields['teacher'] as String?,
      updatedAt: DateTime.now(),
    );

    await ref.read(updateScheduleProvider)(updated);
  }
  // ---------------- Notes ----------------

  Future<void> _executeNotesCreate(
    AssistantIntent intent,
    Subject subject,
  ) async {
    final content = (intent.fields['content'] as String?)?.trim();
    if (content == null || content.isEmpty) {
      throw ArgumentError('No note content was understood.');
    }
    await ref.read(notesControllerProvider(subject.id)).createTextNote(content);
  }

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

  bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return null;
  }

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
