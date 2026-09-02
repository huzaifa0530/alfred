import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/event_reminder_storage.dart'; // <-- add this
import '../controllers/events_providers.dart';
import '../../domain/entities/event.dart';

class SetReminderSheet extends ConsumerStatefulWidget {
  // ... rest of file unchanged, no other code changes needed
  final Event event;
  const SetReminderSheet({super.key, required this.event});

  @override
  ConsumerState<SetReminderSheet> createState() => _SetReminderSheetState();
}

class _SetReminderSheetState extends ConsumerState<SetReminderSheet> {
  DateTime? _dateTime;
  ReminderType _type = ReminderType.notification;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.event.dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;

    setState(() {
      _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (_dateTime == null) return;

    await ref.read(notificationServiceProvider).scheduleEventReminder(
          eventId: widget.event.id,
          title: 'Alfred reminds you',
          body: widget.event.title,
          dateTime: _dateTime!,
          type: _type,
        );

    await ref.read(eventReminderStorageProvider).set(
          widget.event.id,
          EventReminderInfo(dateTime: _dateTime!, type: _type),
        );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Remind me about "${widget.event.title}"',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _pickDateTime,
            icon: const Icon(Icons.schedule_rounded),
            label: Text(_dateTime == null ? 'Choose date & time' : _dateTime.toString()),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Notification'),
                selected: _type == ReminderType.notification,
                onSelected: (_) => setState(() => _type = ReminderType.notification),
              ),
              ChoiceChip(
                label: const Text('Alarm'),
                selected: _type == ReminderType.alarm,
                onSelected: (_) => setState(() => _type = ReminderType.alarm),
              ),
              ChoiceChip(
                label: const Text('Both'),
                selected: _type == ReminderType.both,
                onSelected: (_) => setState(() => _type = ReminderType.both),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _dateTime == null ? null : _save,
              child: const Text('Set reminder'),
            ),
          ),
        ],
      ),
    );
  }
}