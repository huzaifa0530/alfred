import 'package:alfred/core/database/database_providers.dart';
import 'package:alfred/core/notifications/recurring_alarm_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/daos/events_dao.dart';

import '../../data/datasources/events_local_datasource.dart';
import '../../data/repositories/events_repository_impl.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/events_repository.dart';


import '../../domain/usecases/create_event.dart';
import '../../domain/usecases/update_event.dart';
import '../../domain/usecases/delete_event.dart';
import '../../domain/usecases/mark_event_completed.dart';
import '../../../../core/storage/event_order_storage.dart';
import '../../../../core/storage/event_reminder_storage.dart';
import '../../../../core/notifications/notification_service.dart';


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


final createEventProvider = Provider<CreateEvent>((ref) {
  return CreateEvent(ref.watch(eventsRepositoryProvider));
});
final updateEventProvider = Provider<UpdateEvent>((ref) {
  return UpdateEvent(ref.watch(eventsRepositoryProvider));
});
final deleteEventProvider = Provider<DeleteEvent>((ref) {
  return DeleteEvent(ref.watch(eventsRepositoryProvider));
});
final markEventCompletedProvider = Provider<MarkEventCompleted>((ref) {
  return MarkEventCompleted(ref.watch(eventsRepositoryProvider));
});


final eventOrderStorageProvider = Provider<EventOrderStorage>((ref) {
  return EventOrderStorage();
});

final eventReminderStorageProvider = Provider<EventReminderStorage>((ref) {
  return EventReminderStorage();
});


final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
