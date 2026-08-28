import 'package:shared_preferences/shared_preferences.dart';

class SettingsLocalDataSource {
  static const _autoBackupKey = 'auto_backup_enabled';
  static const _lastBackupKey = 'last_backup_at';

  Future<bool> getAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupKey) ?? false;
  }

  Future<void> setAutoBackupEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, value);
  }

  Future<DateTime?> getLastBackupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastBackupKey);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastBackupAt(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBackupKey, value.millisecondsSinceEpoch);
  }
}