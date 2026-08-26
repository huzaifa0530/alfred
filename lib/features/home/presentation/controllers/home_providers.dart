import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/controllers/events_providers.dart';
import '../../../subjects/domain/entities/subject.dart';
import '../../../subjects/presentation/controllers/subjects_controller.dart';
import '../../../subjects/presentation/controllers/subjects_providers.dart';

final nextEventProvider = Provider<Event?>((ref) {
  final eventsAsync = ref.watch(allEventsProvider);

  return eventsAsync.maybeWhen(
    data: (events) {
      final upcoming = events
          .where((event) => !event.isCompleted)
          .where(
            (event) =>
                event.dueDate.isAfter(
              DateTime.now(),
            ),
          )
          .toList();

      if (upcoming.isEmpty) {
        return null;
      }

      upcoming.sort(
        (a, b) =>
            a.dueDate.compareTo(b.dueDate),
      );

      return upcoming.first;
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