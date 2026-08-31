import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

enum ReminderType { notification, alarm, both }

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    _initialized = true;
  }

  Future<void> scheduleEventReminder({
    required int eventId,
    required String title,
    required String body,
    required DateTime dateTime,
    required ReminderType type,
  }) async {
    await init();

    final isAlarmStyle = type == ReminderType.alarm || type == ReminderType.both;

    final androidDetails = AndroidNotificationDetails(
      'alfred_event_reminders',
      'Event Reminders',
      channelDescription: 'Reminders for notes, quizzes, and deadlines',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: isAlarmStyle,
      sound: isAlarmStyle
          ? const RawResourceAndroidNotificationSound('alarm_sound') // add res/raw/alarm_sound.mp3, or remove this line to use the default sound
          : null,
      playSound: true,
      category: isAlarmStyle ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(presentSound: true, presentAlert: true),
    );

    await _plugin.zonedSchedule(
      id: eventId, // reuse the event's id as the notification id — makes cancel/reschedule trivial
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(dateTime, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelEventReminder(int eventId) async {
    await init();
    await _plugin.cancel(id: eventId);
  }
}