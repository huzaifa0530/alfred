import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notes/domain/usecases/parse_note_prompt.dart';
import '../../../notes/presentation/controllers/notes_controller.dart';
import '../../../notes/presentation/controllers/notes_providers.dart';
import '../../../subjects/domain/entities/subject.dart';
import '../../../subjects/presentation/controllers/subjects_controller.dart';

class AskAlfredSheet extends ConsumerStatefulWidget {
  const AskAlfredSheet({super.key});

  @override
  ConsumerState<AskAlfredSheet> createState() => _AskAlfredSheetState();
}

class _AskAlfredSheetState extends ConsumerState<AskAlfredSheet> {
  final _promptController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isProcessing = false;
  ParsedNotePrompt? _parsed;
  Subject? _selectedSubject;

  @override
  void dispose() {
    _promptController.dispose();
    _contentController.dispose();
    super.dispose();
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
              child: Text('Add a subject first, then Alfred can save notes to it.'),
            );
          }

          return _parsed == null
              ? _buildPromptStep(subjects)
              : _buildConfirmStep(subjects);
        },
      ),
    );
  }

  Widget _buildPromptStep(List<Subject> subjects) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ask Alfred',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Try: "Add note to Physics: quiz is Friday, covers chapters 3-4"',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _promptController,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Type what you want Alfred to save…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isProcessing ? null : () => _handlePrompt(subjects),
            icon: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(_isProcessing ? 'Thinking…' : 'Send to Alfred'),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep(List<Subject> subjects) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Save this note?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Subject>(
          initialValue: _selectedSubject,
          decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
          items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
          onChanged: (value) => setState(() => _selectedSubject = value),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _contentController,
          minLines: 2,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Note content', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing ? null : () => setState(() => _parsed = null),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _isProcessing || _selectedSubject == null ? null : _handleConfirm,
                child: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add note'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handlePrompt(List<Subject> subjects) async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final parser = ref.read(parseNotePromptProvider);
      final result = await parser(
        prompt: prompt,
        subjectNames: subjects.map((s) => s.name).toList(),
      );

      if (!mounted) return;

      if (!result.isNoteIntent) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('That didn\'t sound like a note. Try: "Add note to <subject>: ..."'),
          ),
        );
        return;
      }

      final matched = _matchSubject(result.subjectName, subjects);

      setState(() {
        _parsed = result;
        _selectedSubject = matched ?? subjects.first;
        _contentController.text = result.content;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alfred could not process that: $e')),
      );
    }
  }

  Subject? _matchSubject(String? name, List<Subject> subjects) {
    if (name == null || name.trim().isEmpty) return null;

    final target = name.trim().toLowerCase();

    for (final subject in subjects) {
      if (subject.name.toLowerCase() == target) return subject;
    }
    for (final subject in subjects) {
      if (subject.name.toLowerCase().contains(target) ||
          target.contains(subject.name.toLowerCase())) {
        return subject;
      }
    }
    return null;
  }

  Future<void> _handleConfirm() async {
    final subject = _selectedSubject;
    final content = _contentController.text.trim();

    if (subject == null || content.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final controller = ref.read(notesControllerProvider(subject.id));
      await controller.createTextNote(content);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to ${subject.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save note: $e')),
      );
    }
  }
}