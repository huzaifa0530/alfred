import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyEnabled = 'recurring_alarm_enabled';
const _keyIntervalMinutes = 'recurring_alarm_interval_minutes';

class RecurringAlarmService {
  static final RecurringAlarmService _instance = RecurringAlarmService._();
  factory RecurringAlarmService() => _instance;
  RecurringAlarmService._();

  Timer? _timer;
  final _plugin = FlutterLocalNotificationsPlugin();

  /// Call once at app startup — resumes the timer if it was left enabled
  /// last session (so reopening the app picks back up automatically).
  Future<void> restoreIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? false;
    if (enabled) {
      final minutes = prefs.getInt(_keyIntervalMinutes) ?? 20;
      _startTimer(minutes);
    }
  }

  Future<void> start(int intervalMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, true);
    await prefs.setInt(_keyIntervalMinutes, intervalMinutes);
    _startTimer(intervalMinutes);
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, false);
  }

  void _startTimer(int minutes) {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(minutes: minutes), (_) => _fire());
  }

  Future<void> _fire() async {
    const androidDetails = AndroidNotificationDetails(
      'alfred_focus_reminders',
      'Focus Reminders',
      channelDescription: 'Periodic study/focus check-ins',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true),
    );
    await _plugin.show(
      id: 998,
      title: 'Alfred checking in',
      body: 'Still at it, Master Wayne? Time for a quick review.',
      notificationDetails: details,
    );
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  Future<int> getIntervalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyIntervalMinutes) ?? 20;
  }
}
