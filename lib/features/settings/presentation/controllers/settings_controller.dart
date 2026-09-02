import 'dart:io';

import 'package:alfred/core/ai/ai_provider.dart';
import 'package:alfred/core/ai/ai_settings_datasource.dart';
import 'package:alfred/features/backup/backup_service.dart';
import 'package:alfred/features/settings/presentation/controllers/setting_provider.dart';
import 'package:file_picker/file_picker.dart';
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
  final String? aiApiKey; // null = not set

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
      aiApiKey: identical(aiApiKey, _unset)
          ? this.aiApiKey
          : aiApiKey as String?,
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

  Future<void> setAutoBackupEnabled(bool value) async {
    await _localDataSource.setAutoBackupEnabled(value);

    final current = state.value;
    state = AsyncData(current!.copyWith(autoBackupEnabled: value));

    if (value) {
      await backupNow(silent: true);
    }
  }

  Future<void> setAiProvider(AiProvider provider) async {
    await _aiSettings.setProvider(provider);
    final existingKey = await _aiSettings.getApiKey(provider);
    final model = provider.defaultModel;
    await _aiSettings.setModel(model);

    final current = state.value;
    state = AsyncData(
      current!.copyWith(
        aiProvider: provider,
        aiModel: model,
        aiApiKey: existingKey,
      ),
    );
  }

  Future<List<File>> listAvailableBackups() {
    return _backupService.listBackups();
  }

  /// Restores directly from an already-known backup file — used when the
  /// user picks one from the in-app list, no system file picker involved.
  Future<bool> restoreFromFile(File file) async {
    final current = state.value;
    state = AsyncData(current!.copyWith(isRestoring: true));

    try {
      final db = ref.read(appDatabaseProvider);
      await db.close();

      await _backupService.restoreBackup(file);

      return true;
    } finally {
      final updated = state.value;
      state = AsyncData(updated!.copyWith(isRestoring: false));
    }
  }

  /// Fallback for a backup that isn't in the Alfred Backups folder —
  /// e.g. one received via WhatsApp and saved somewhere else manually.
  Future<bool> restoreFromPickedFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'alfredbackup',
        'zip',
      ], // accept both, in case of older backups
    );

    if (result.isEmpty) return false;

    final path = result.first.path;
    if (path == null) return false;

    return restoreFromFile(File(path));
  }

  Future<void> setAiModel(String model) async {
    await _aiSettings.setModel(model);
    final current = state.value;
    state = AsyncData(current!.copyWith(aiModel: model));
  }

  Future<void> setAiApiKey(String apiKey) async {
    final current = state.value!;
    await _aiSettings.setApiKey(current.aiProvider, apiKey);
    state = AsyncData(current.copyWith(aiApiKey: apiKey));
  }

  /// Call this from app startup and from the Settings screen — matches
  /// "auto backup happens when the app opens or Settings is visited".
  Future<void> maybeRunAutoBackupOnOpen() async {
    final enabled = await _localDataSource.getAutoBackupEnabled();
    if (!enabled) return;

    await backupNow(silent: true);
  }

  Future<File?> backupNow({bool silent = false}) async {
    final current = state.value;
    state = AsyncData(current!.copyWith(isBackingUp: true));

    try {
      final file = await _backupService.createBackup();
      final now = DateTime.now();
      await _localDataSource.setLastBackupAt(now);

      final updated = state.value;
      state = AsyncData(
        updated!.copyWith(lastBackupAt: now, isBackingUp: false),
      );
      return file;
    } catch (e) {
      final updated = state.value;
      state = AsyncData(updated!.copyWith(isBackingUp: false));
      if (!silent) rethrow;
      return null;
    }
  }

  Future<void> shareBackup(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Alfred backup');
  }

  /// Lets the user pick a .zip and restore it. Returns true if a restore
  /// Lets the user pick a .zip and restore it. Returns true if a restore
  /// actually ran — caller should then tell the user to restart the app.
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsState>(
      SettingsController.new,
    );
