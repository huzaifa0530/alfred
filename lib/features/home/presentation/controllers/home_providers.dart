import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/controllers/events_providers.dart';
import '../../../subjects/domain/entities/subject.dart';
import '../../../subjects/presentation/controllers/subjects_controller.dart';

final nextEventProvider = Provider<Event?>((ref) {
  final eventsAsync = ref.watch(allEventsProvider);
  final manualOrderAsync = ref.watch(manualEventOrderProvider);

  return eventsAsync.maybeWhen(
    data: (events) {
      final manualOrder = manualOrderAsync.value ?? const <int>[];

      final activeEvents = events
          .where((event) => !event.isCompleted)
          .toList();

      if (activeEvents.isEmpty) {
        return null;
      }

      final now = DateTime.now();

      final today = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final tomorrow = today.add(
        const Duration(days: 1),
      );

      final thisWeekEnd = today.add(
        const Duration(days: 7),
      );

      int category(Event event) {
        final eventDate = DateTime(
          event.dueDate.year,
          event.dueDate.month,
          event.dueDate.day,
        );

        // Highest priority
        if (eventDate.isBefore(today)) {
          return 0;
        }

        if (eventDate == today) {
          return 1;
        }

        if (eventDate == tomorrow) {
          return 2;
        }

        if (eventDate.isBefore(thisWeekEnd)) {
          return 3;
        }

        return 4;
      }

      final manualIndex = {
        for (var i = 0; i < manualOrder.length; i++)
          manualOrder[i]: i,
      };

      activeEvents.sort((a, b) {
        // ----------------------------------------------------------
        // FIRST: Event section priority
        //
        // Overdue → Today → Tomorrow → This Week → Later
        // ----------------------------------------------------------

        final categoryComparison =
            category(a).compareTo(category(b));

        if (categoryComparison != 0) {
          return categoryComparison;
        }

        // ----------------------------------------------------------
        // SECOND: Manual order
        //
        // This makes manually arranged events win within
        // the same section.
        // ----------------------------------------------------------

        final aIndex = manualIndex[a.id];
        final bIndex = manualIndex[b.id];

        if (aIndex != null && bIndex != null) {
          return aIndex.compareTo(bIndex);
        }

        if (aIndex != null) {
          return -1;
        }

        if (bIndex != null) {
          return 1;
        }

        // ----------------------------------------------------------
        // THIRD: Date/time fallback
        // ----------------------------------------------------------

        return a.dueDate.compareTo(b.dueDate);
      });

      return activeEvents.first;
    },
    orElse: () => null,
  );
});

final homeSubjectsProvider =
    Provider<List<Subject>>((ref) {
  final subjectsAsync =
        ref.watch(subjectsControllerProvider);

  return subjectsAsync.maybeWhen(
    data: (subjects) => subjects,
    orElse: () => const [],
  );
});