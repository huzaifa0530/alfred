
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../subjects/presentation/controllers/subjects_controller.dart';
import '../../../subjects/presentation/controllers/subjects_providers.dart';
import '../../domain/entities/class_schedule.dart';
import '../controllers/timetable_providers.dart';

class CreateClassScreen extends ConsumerStatefulWidget {
  final ClassSchedule? schedule;

  const CreateClassScreen({
    super.key,
    this.schedule,
  });

  bool get isEditing => schedule != null;

  @override
  ConsumerState<CreateClassScreen> createState() =>
      _CreateClassScreenState();
}

class _CreateClassScreenState
    extends ConsumerState<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();

  final _roomController = TextEditingController();
  final _teacherController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedSubjectId;

  int _weekday = DateTime.now().weekday;

  TimeOfDay _startTime =
      const TimeOfDay(hour: 9, minute: 0);

  TimeOfDay _endTime =
      const TimeOfDay(hour: 10, minute: 0);

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final schedule = widget.schedule;

    if (schedule != null) {
      _selectedSubjectId = schedule.subjectId;
      _weekday = schedule.weekday;

      _startTime = _parseTime(schedule.startTime);
      _endTime = _parseTime(schedule.endTime);

      _roomController.text = schedule.room ?? '';
      _teacherController.text = schedule.teacher ?? '';
      _notesController.text = schedule.notes ?? '';
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
    _teacherController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit class' : 'Add class',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            40,
          ),
          children: [
            // ─────────────────────────────
            // DAY
            // ─────────────────────────────

            DropdownButtonFormField<int>(
              value: _weekday,
              decoration: const InputDecoration(
                labelText: 'Day',
                prefixIcon:
                    Icon(Icons.calendar_today_outlined),
              ),
              items: List.generate(
                7,
                (index) {
                  final day = index + 1;

                  return DropdownMenuItem<int>(
                    value: day,
                    child: Text(
                      _weekdayName(day),
                    ),
                  );
                },
              ),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _weekday = value;
                });
              },
            ),

            const SizedBox(height: 18),

            // ─────────────────────────────
            // SUBJECT
            // ─────────────────────────────

            subjectsAsync.when(
              loading: () {
                return const InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    prefixIcon:
                        Icon(Icons.menu_book_outlined),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      'Loading subjects...',
                    ),
                  ),
                );
              },
              error: (error, stack) {
                return InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon:
                        Icon(Icons.error_outline_rounded),
                  ),
                  child: const Text(
                    'Unable to load subjects',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                );
              },
              data: (subjects) {
                if (subjects.isEmpty) {
                  return InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      prefixIcon: Icon(
                        Icons.menu_book_outlined,
                      ),
                    ),
                    child: const Text(
                      'Add a subject first',
                    ),
                  );
                }

                return DropdownButtonFormField<int>(
                  value: _selectedSubjectId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(
                      Icons.menu_book_outlined,
                    ),
                  ),
                  items: subjects.map((subject) {
                    return DropdownMenuItem<int>(
                      value: subject.id,
                      child: Text(
                        subject.name,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    final selectedSubject =
                        subjects.firstWhere(
                      (subject) =>
                          subject.id == value,
                    );

                    setState(() {
                      _selectedSubjectId = value;

                      // Automatically take these values
                      // from the selected subject.
                      _roomController.text =
                          selectedSubject.room ?? '';

                      _teacherController.text =
                          selectedSubject.instructor ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Select a subject';
                    }

                    return null;
                  },
                );
              },
            ),

            const SizedBox(height: 18),

            // ─────────────────────────────
            // TIME
            // ─────────────────────────────

            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Start',
                    time: _startTime,
                    icon:
                        Icons.play_arrow_outlined,
                    onTap: _selectStartTime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeField(
                    label: 'End',
                    time: _endTime,
                    icon:
                        Icons.stop_outlined,
                    onTap: _selectEndTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ─────────────────────────────
            // ROOM
            // ─────────────────────────────

            TextFormField(
              controller: _roomController,
              textInputAction:
                  TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Room',
                hintText:
                    'Automatically filled from subject',
                prefixIcon:
                    Icon(Icons.location_on_outlined),
              ),
            ),

            const SizedBox(height: 18),

            // ─────────────────────────────
            // INSTRUCTOR
            // ─────────────────────────────

            TextFormField(
              controller: _teacherController,
              textInputAction:
                  TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Instructor',
                hintText:
                    'Automatically filled from subject',
                prefixIcon:
                    Icon(Icons.person_outline_rounded),
              ),
            ),

            const SizedBox(height: 18),

            // ─────────────────────────────
            // NOTES
            // ─────────────────────────────

            TextFormField(
              controller: _notesController,
              maxLines: 4,
              textInputAction:
                  TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText:
                    'Optional notes about this class',
                prefixIcon:
                    Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 30),

            // ─────────────────────────────
            // SAVE / UPDATE
            // ─────────────────────────────

            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed:
                    _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.isEditing
                            ? 'Update class'
                            : 'Save class',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // START TIME
  // ─────────────────────────────────────

  Future<void> _selectStartTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (result == null) return;

    setState(() {
      _startTime = result;
    });
  }

  // ─────────────────────────────────────
  // END TIME
  // ─────────────────────────────────────

  Future<void> _selectEndTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (result == null) return;

    setState(() {
      _endTime = result;
    });
  }

  // ─────────────────────────────────────
  // SAVE / UPDATE
  // ─────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSubjectId == null) {
      return;
    }

    if (_toMinutes(_endTime) <=
        _toMinutes(_startTime)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'End time must be after start time.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final now = DateTime.now();

      final schedule = ClassSchedule(
        id: widget.schedule?.id ?? 0,
        subjectId: _selectedSubjectId!,
        weekday: _weekday,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        room: _emptyToNull(
          _roomController.text,
        ),
        teacher: _emptyToNull(
          _teacherController.text,
        ),
        notes: _emptyToNull(
          _notesController.text,
        ),
        isActive:
            widget.schedule?.isActive ?? true,
        createdAt:
            widget.schedule?.createdAt ?? now,
        updatedAt: now,
      );

      final repository =
          ref.read(timetableRepositoryProvider);

      if (widget.isEditing) {
        await repository.updateSchedule(schedule);
      } else {
        await repository.createSchedule(schedule);
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Unable to update class: $error'
                : 'Unable to save class: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ─────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────

  int _toMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.period == DayPeriod.am
            ? 'AM'
            : 'PM';

    return '$hour:$minute $period';
  }

  TimeOfDay _parseTime(String value) {
    try {
      final parts = value.trim().split(' ');

      if (parts.length < 2) {
        return const TimeOfDay(
          hour: 9,
          minute: 0,
        );
      }

      final timeParts = parts[0].split(':');

      final parsedHour =
          int.parse(timeParts[0]);

      final parsedMinute =
          int.parse(timeParts[1]);

      final period =
          parts[1].toUpperCase();

      var hour = parsedHour;

      if (period == 'PM' && hour != 12) {
        hour += 12;
      }

      if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(
        hour: hour,
        minute: parsedMinute,
      );
    } catch (_) {
      return const TimeOfDay(
        hour: 9,
        minute: 0,
      );
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();

    return trimmed.isEmpty
        ? null
        : trimmed;
  }

  String _weekdayName(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[day - 1];
  }
}

// ─────────────────────────────────────────
// TIME FIELD
// ─────────────────────────────────────────

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final IconData icon;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        child: Text(
          time.format(context),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

