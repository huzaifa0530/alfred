import 'package:alfred/features/backup/backup_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/settings_local_datasource.dart';

final backupServiceProvider = Provider<BackupService>((ref) => BackupService());

final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>((ref) {
  return SettingsLocalDataSource();
});