import 'dart:io';

import 'package:alfred/core/ai/ai_provider.dart';
import 'package:alfred/core/ai/ai_settings_datasource.dart';
import 'package:alfred/features/backup/backup_service.dart';
import 'package:alfred/features/settings/presentation/controllers/setting_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/database/database_providers.dart';
import '../../data/datasources/settings_local_datasource.dart';

class SettingsState {
  final bool autoBackupEnabled;
  final DateTime? lastBackupAt;
  final bool isBackingUp;
  final bool isRestoring;
  final AiProvider aiProvider;
  final String aiModel;
  final String? aiApiKey;

  const SettingsState({
    required this.autoBackupEnabled,
    required this.lastBackupAt,
    this.isBackingUp = false,
    this.isRestoring = false,
    required this.aiProvider,
    required this.aiModel,
    this.aiApiKey,
  });

  SettingsState copyWith({
    bool? autoBackupEnabled,
    DateTime? lastBackupAt,
    bool? isBackingUp,
    bool? isRestoring,
    AiProvider? aiProvider,
    String? aiModel,
    Object? aiApiKey = _unset,
  }) {
    return SettingsState(
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      isRestoring: isRestoring ?? this.isRestoring,
      aiProvider: aiProvider ?? this.aiProvider,
      aiModel: aiModel ?? this.aiModel,
      aiApiKey: identical(aiApiKey, _unset) ? this.aiApiKey : aiApiKey as String?,
    );
  }

  static const _unset = Object();
}

class SettingsController extends AsyncNotifier<SettingsState> {
  late final BackupService _backupService;
  late final SettingsLocalDataSource _localDataSource;
  late final AiSettingsDataSource _aiSettings;

  @override
  Future<SettingsState> build() async {
    _backupService = ref.watch(backupServiceProvider);
    _localDataSource = ref.watch(settingsLocalDataSourceProvider);
    _aiSettings = AiSettingsDataSource();

    final provider = await _aiSettings.getProvider();

    return SettingsState(
      autoBackupEnabled: await _localDataSource.getAutoBackupEnabled(),
      lastBackupAt: await _localDataSource.getLastBackupAt(),
      aiProvider: provider,
      aiModel: await _aiSettings.getModel() ?? provider.defaultModel,
      aiApiKey: await _aiSettings.getApiKey(provider),
    );
  }

  // SAFE helper
  void _updateState(SettingsState Function(SettingsState) updater) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(updater(current));
  }

  void setRestoring(bool value) {
    _updateState((s) => s.copyWith(isRestoring: value));
  }

  Future<void> setAutoBackupEnabled(bool value) async {
    await _localDataSource.setAutoBackupEnabled(value);
    _updateState((s) => s.copyWith(autoBackupEnabled: value));
    if (value) {
      await backupNow(silent: true);
    }
  }

  Future<void> setAiProvider(AiProvider provider) async {
    await _aiSettings.setProvider(provider);
    final existingKey = await _aiSettings.getApiKey(provider);
    final model = provider.defaultModel;
    await _aiSettings.setModel(model);
    _updateState((s) => s.copyWith(
          aiProvider: provider,
          aiModel: model,
          aiApiKey: existingKey,
        ));
  }

  Future<List<File>> listAvailableBackups() {
    return _backupService.listBackups();
  }

Future<bool> restoreFromFile(File file) async {
  _updateState((s) => s.copyWith(isRestoring: true));
  try {
    // Close DB - after this DO NOT read any provider that needs DB
    final db = ref.read(appDatabaseProvider);
    await db.close();

    // This should ONLY copy files, not try to open DB again
    await _backupService.restoreBackup(file);
    
    // SUCCESS - keep isRestoring = true, so UI stays in "restart needed" state
    // Don't set it back to false, app will be restarted manually
    return true;
  } catch (e, st) {
    debugPrint('RESTORE FAILED: $e\n$st');
    // Only on failure, set back to false
    _updateState((s) => s.copyWith(isRestoring: false));
    rethrow;
  }
}
  Future<bool> restoreFromPickedFile() async {
    final List<PlatformFile> result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['alfredbackup', 'zip'],
    );
    if (result.isEmpty) return false;
    final path = result.first.path;
    if (path == null) return false;
    return restoreFromFile(File(path));
  }

  Future<void> setAiModel(String model) async {
    await _aiSettings.setModel(model);
    _updateState((s) => s.copyWith(aiModel: model));
  }

  Future<void> setAiApiKey(String apiKey) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _aiSettings.setApiKey(current.aiProvider, apiKey);
    _updateState((s) => s.copyWith(aiApiKey: apiKey));
  }

  Future<void> maybeRunAutoBackupOnOpen() async {
    // Don't use state.value here - it can be null
    final enabled = await _localDataSource.getAutoBackupEnabled();
    if (!enabled) return;
    // Only backup if we already have a loaded state
    final current = state.asData?.value;
    if (current == null) return;
    if (current.isBackingUp || current.isRestoring) return;

    await backupNow(silent: true);
  }

  Future<File?> backupNow({bool silent = false}) async {
    final current = state.asData?.value;
    if (current == null) {
      // This is your line 171 crash fix
      if (!silent) throw StateError('Settings not loaded yet');
      return null;
    }

    _updateState((s) => s.copyWith(isBackingUp: true));

    try {
      final file = await _backupService.createBackup();
      final now = DateTime.now();
      await _localDataSource.setLastBackupAt(now);
      _updateState((s) => s.copyWith(lastBackupAt: now, isBackingUp: false));
      return file;
    } catch (e) {
      _updateState((s) => s.copyWith(isBackingUp: false));
      if (!silent) rethrow;
      return null;
    }
  }

  Future<void> shareBackup(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Alfred backup');
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);