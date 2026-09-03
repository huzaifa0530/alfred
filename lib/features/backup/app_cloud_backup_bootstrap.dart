// features/backup/app_cloud_backup_bootstrap.dart
import '../../core/firebase/firebase_credentials_storage.dart';
import '../../core/firebase/dynamic_firebase_app.dart';
import 'auto_backup_scheduler.dart';

/// Call once during app startup, after your local DB/services are
/// ready but before the first frame really needs to be interactive —
/// safe to run in the background since it never throws.
class AppCloudBackupBootstrap {
  final FirebaseCredentialsStorage credentialsStorage;
  final DynamicFirebaseApp firebaseApp;
  final AutoBackupScheduler autoBackupScheduler;

  AppCloudBackupBootstrap({
    required this.credentialsStorage,
    required this.firebaseApp,
    required this.autoBackupScheduler,
  });

  /// Silently reconnects to the user's saved Firebase project (if any)
  /// and triggers the daily-if-due backup check. Never throws —
  /// failures here shouldn't block app startup.
  Future<void> run() async {
    try {
      final creds = await credentialsStorage.read();
      if (creds == null) return; // user never connected Firebase — fine

      await firebaseApp.connect(creds);
      await autoBackupScheduler.runIfDue();
    } catch (_) {
      // Bad/stale credentials, offline, project deleted, etc.
      // Local backups still work regardless — just skip cloud silently.
      // Settings screen will show "not connected" and let them re-auth.
    }
  }
}