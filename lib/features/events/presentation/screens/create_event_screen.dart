import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../subjects/domain/entities/subject.dart';
import '../../../subjects/presentation/controllers/subjects_controller.dart';
import '../../../subjects/presentation/controllers/subjects_providers.dart';
import '../../domain/entities/event.dart';
import '../controllers/events_providers.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() =>
      _CreateEventScreenState();
}

class _CreateEventScreenState
    extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _subjectId;

  String _selectedType = 'quiz';
  String _selectedPriority = 'normal';

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _isSaving = false;

  final List<String> _eventTypes = const [
    'quiz',
    'assignment',
    'exam',
    'presentation',
    'project',
    'custom',
  ];

  final List<String> _priorities = const [
    'low',
    'normal',
    'high',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (result == null) return;

    setState(() {
      _selectedDate = result;
    });
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (result == null) return;

    setState(() {
      _selectedTime = result;
    });
  }

  DateTime _getDueDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();

      final event = Event(
        id: 0,
        subjectId: _subjectId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        type: _selectedType,
        priority: _selectedPriority,
        dueDate: _getDueDateTime(),
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );

      await ref
          .read(eventsRepositoryProvider)
          .createEvent(event);

      if (!mounted) return;

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create event: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _capitalize(String value) {
    return value[0].toUpperCase() + value.substring(1);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Event'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: subjectsAsync.when(
          loading: () =>
              const Center(
            child: CircularProgressIndicator(),
          ),
          error: (_, __) => _buildContent(
            context,
            const [],
          ),
          data: (subjects) => _buildContent(
            context,
            subjects,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Subject> subjects,
  ) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          32,
        ),
        children: [
          Text(
            'What do you need to do?',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          TextFormField(
            controller: _titleController,
            textCapitalization:
                TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. Assignment 3',
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Enter an event title';
              }

              return null;
            },
          ),

          const SizedBox(height: 28),

          _SectionLabel(label: 'TYPE'),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _eventTypes.map((type) {
              final selected =
                  _selectedType == type;

              return ChoiceChip(
                label: Text(
                  _capitalize(type),
                ),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _selectedType = type;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          _SectionLabel(label: 'SUBJECT'),

          const SizedBox(height: 10),

          _SubjectSelector(
            subjects: subjects,
            selectedSubjectId: _subjectId,
            onChanged: (id) {
              setState(() {
                _subjectId = id;
              });
            },
          ),

          const SizedBox(height: 28),

          _SectionLabel(label: 'WHEN'),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _SelectorButton(
                  icon: Icons.calendar_today_outlined,
                  label: _formatDate(
                    _selectedDate,
                  ),
                  onTap: _pickDate,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _SelectorButton(
                  icon: Icons.schedule_outlined,
                  label: _formatTime(
                    _selectedTime,
                  ),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          _SectionLabel(label: 'PRIORITY'),

          const SizedBox(height: 10),

          Row(
            children: _priorities.map((priority) {
              final selected =
                  _selectedPriority ==
                      priority;

              return Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(
                    right: priority !=
                            _priorities.last
                        ? 8
                        : 0,
                  ),
                  child: ChoiceChip(
                    label: SizedBox(
                      width: double.infinity,
                      child: Text(
                        _capitalize(priority),
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedPriority =
                            priority;
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          _SectionLabel(label: 'NOTES'),

          const SizedBox(height: 10),

          TextField(
            controller: _descriptionController,
            minLines: 4,
            maxLines: 6,
            textCapitalization:
                TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Add details...',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 32),

          FilledButton(
            onPressed: _isSaving
                ? null
                : _createEvent,
            style: FilledButton.styleFrom(
              minimumSize:
                  const Size.fromHeight(54),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Create Event',
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .labelSmall
          ?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
    );
  }
}

class _SelectorButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SelectorButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color:
          theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectSelector extends StatelessWidget {
  final List<Subject> subjects;
  final int? selectedSubjectId;
  final ValueChanged<int?> onChanged;

  const _SubjectSelector({
    required this.subjects,
    required this.selectedSubjectId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      value: selectedSubjectId,
      isExpanded: true,
      decoration: const InputDecoration(
        hintText: 'General / No subject',
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('General / No subject'),
        ),
        ...subjects.map(
          (subject) =>
              DropdownMenuItem<int?>(
            value: subject.id,
            child: Text(
              subject.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}