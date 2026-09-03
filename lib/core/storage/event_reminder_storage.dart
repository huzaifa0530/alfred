import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifications/notification_service.dart';

class EventReminderInfo {
  final DateTime dateTime;
  final ReminderType type;
  const EventReminderInfo({required this.dateTime, required this.type});

  Map<String, dynamic> toJson() => {
        'dateTime': dateTime.toIso8601String(),
        'type': type.name,
      };

  factory EventReminderInfo.fromJson(Map<String, dynamic> json) {
    return EventReminderInfo(
      dateTime: DateTime.parse(json['dateTime'] as String),
      type: ReminderType.values.firstWhere((t) => t.name == json['type']),
    );
  }
}

class EventReminderStorage {
  static const _keyPrefix = 'event_reminder_';

  Future<EventReminderInfo?> get(int eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$eventId');
    if (raw == null) return null;
    return EventReminderInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> set(int eventId, EventReminderInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$eventId', jsonEncode(info.toJson()));
  }

  Future<void> clear(int eventId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$eventId');
  }
}