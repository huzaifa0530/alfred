import 'package:alfred/core/firebase/dynamic_firebase_app.dart';
import 'package:alfred/core/firebase/firebase_credentials_storage.dart';
import 'package:alfred/features/backup/app_cloud_backup_bootstrap.dart';
import 'package:alfred/features/backup/auto_backup_scheduler.dart';
import 'package:alfred/features/backup/cloud_backup_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backup_service.dart';

final dynamicFirebaseAppProvider = Provider((ref) => DynamicFirebaseApp());

final backupServiceProvider = Provider((ref) => BackupService());

final cloudBackupServiceProvider = Provider((ref) {
  return CloudBackupService(
    firebaseApp: ref.watch(dynamicFirebaseAppProvider),
    localBackupService: ref.watch(backupServiceProvider),
  );
});

final autoBackupSchedulerProvider = Provider((ref) {
  return AutoBackupScheduler(ref.watch(cloudBackupServiceProvider));
});
final firebaseCredentialsStorageProvider = Provider((ref) => FirebaseCredentialsStorage());

final appCloudBackupBootstrapProvider = Provider((ref) {
  return AppCloudBackupBootstrap(
    credentialsStorage: ref.watch(firebaseCredentialsStorageProvider),
    firebaseApp: ref.watch(dynamicFirebaseAppProvider),
    autoBackupScheduler: ref.watch(autoBackupSchedulerProvider),
  );
});