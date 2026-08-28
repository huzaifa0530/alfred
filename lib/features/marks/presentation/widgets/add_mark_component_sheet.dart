import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../subjects/domain/entities/subject.dart';

import '../../domain/entities/mark_component.dart';

import '../controllers/marks_controller.dart';

class AddMarkComponentSheet extends ConsumerStatefulWidget {
  final List<Subject> subjects;

  const AddMarkComponentSheet({super.key, required this.subjects});

  @override
  ConsumerState<AddMarkComponentSheet> createState() =>
      _AddMarkComponentSheetState();
}

class _AddMarkComponentSheetState extends ConsumerState<AddMarkComponentSheet> {
  final nameController = TextEditingController();
  final maxMarksController = TextEditingController();

  String? selectedType;

  Subject? selectedSubject;

  bool saving = false;

  final types = const [
    'Quiz',
    'Assignment',
    'Midterm',
    'Final',
    'Project',
    'Performance',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.subjects.isNotEmpty) {
      selectedSubject = widget.subjects.first;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    maxMarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add assessment',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Create a quiz, assignment, exam, project or custom assessment.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // SUBJECT
              // ==================================================
              DropdownButtonFormField<Subject>(
                initialValue: selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                items: widget.subjects.map((subject) {
                  return DropdownMenuItem<Subject>(
                    value: subject,
                    child: Text(subject.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSubject = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // ==================================================
              // NAME
              // ==================================================
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Assessment name',
                  hintText: 'Example: Quiz 1',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // TYPE
              // ==================================================
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: types.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedType = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // ==================================================
              // MAX MARKS
              // ==================================================
              TextField(
                controller: maxMarksController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Maximum marks',
                  hintText: 'Example: 10',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // SAVE
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: saving ? null : _createComponent,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded),
                  label: Text(saving ? 'Creating...' : 'Add assessment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createComponent() async {
    final subject = selectedSubject;

    final name = nameController.text.trim();

    final maxMarks = double.tryParse(maxMarksController.text.trim());

    if (subject == null) {
      _showError('Please select a subject.');
      return;
    }

    if (name.isEmpty) {
      _showError('Enter an assessment name.');
      return;
    }

    if (maxMarks == null || maxMarks <= 0) {
      _showError('Enter valid maximum marks.');
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final component = MarkComponent(
        id: 0,
        subjectId: subject.id,
        name: name,
        type: selectedType?.toLowerCase(),
        maxMarks: maxMarks,
        sortOrder: 0,
        createdAt: DateTime.now(),
      );

      await ref.read(marksControllerProvider).createComponent(component);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name added to ${subject.name}.')),
      );
    } catch (e, stack) {
      debugPrint('========================================');
      debugPrint('ADD COMPONENT ERROR: $e');
      debugPrint('ADD COMPONENT STACK: $stack');
      debugPrint('========================================');

      if (!mounted) return;

      _showError('Unable to add assessment: $e');
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
