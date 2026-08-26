import 'package:alfred/core/database/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/daos/events_dao.dart';

import '../../data/datasources/events_local_datasource.dart';
import '../../data/repositories/events_repository_impl.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/events_repository.dart';

final eventsDaoProvider =
    Provider<EventsDao>((ref) {
  return EventsDao(
    ref.watch(appDatabaseProvider),
  );
});

final eventsLocalDataSourceProvider =
    Provider<EventsLocalDataSource>((ref) {
  return EventsLocalDataSource(
    ref.watch(eventsDaoProvider),
  );
});

final eventsRepositoryProvider =
    Provider<EventsRepository>((ref) {
  return EventsRepositoryImpl(
    ref.watch(
      eventsLocalDataSourceProvider,
    ),
  );
});

final allEventsProvider =
    StreamProvider<List<Event>>((ref) {
  return ref
      .watch(eventsRepositoryProvider)
      .watchAllEvents();
});

final upcomingEventsProvider =
    StreamProvider<List<Event>>((ref) {
  return ref
      .watch(eventsRepositoryProvider)
      .watchUpcomingEvents();
});

final subjectEventsProvider =
    StreamProvider.family<List<Event>, int>(
  (ref, subjectId) {
    return ref
        .watch(eventsRepositoryProvider)
        .watchEventsForSubject(subjectId);
  },
);