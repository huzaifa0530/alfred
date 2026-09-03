// features/backup/auto_backup_scheduler.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_backup_service.dart';

class AutoBackupScheduler {
  static const _lastRunKey = 'last_cloud_backup_at';
  final CloudBackupService cloudBackupService;

  AutoBackupScheduler(this.cloudBackupService);

  /// Call this from app startup / onResume. Silently no-ops if Firebase
  /// isn't connected, or if <24h have passed since the last successful run.
  Future<void> runIfDue() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRunMs = prefs.getInt(_lastRunKey);
    final now = DateTime.now();

    if (lastRunMs != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastRunMs);
      if (now.difference(last) < const Duration(hours: 24)) return;
    }

    try {
      await cloudBackupService.syncNow();
      await prefs.setInt(_lastRunKey, now.millisecondsSinceEpoch);
    } catch (_) {
      // Offline, not connected, or transient failure — just try again
      // next launch. Don't surface an error for a background sync.
    }
  }

  // features/backup/auto_backup_scheduler.dart — add this method
  Future<DateTime?> lastRunAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastRunKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }
}
