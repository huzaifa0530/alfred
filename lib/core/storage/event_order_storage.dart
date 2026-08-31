import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EventOrderStorage {
  static const _key = 'event_manual_order';

  Future<List<int>> getOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<int>();
  }

  Future<void> saveOrder(List<int> eventIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(eventIds));
  }

  /// Moves [eventId] to the front of the manual order, pushing everything
  /// else down. Any event never manually touched keeps falling back to
  /// the default priority/date sort.
  Future<void> moveToTop(int eventId) async {
    final current = await getOrder();
    current.remove(eventId);
    current.insert(0, eventId);
    await saveOrder(current);
  }

  Future<void> reorder(List<int> newOrder) async {
    await saveOrder(newOrder);
  }
}