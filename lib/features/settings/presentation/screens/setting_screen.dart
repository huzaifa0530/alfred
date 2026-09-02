import 'dart:io';
import 'dart:typed_data';

import 'package:alfred/app/router/route_names.dart';
import 'package:alfred/core/ai/ai_provider.dart';
import 'package:alfred/core/notifications/recurring_alarm_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../controllers/settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _localRestoring = false; // USE THIS, NOT state.isRestoring

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsControllerProvider.notifier).maybeRunAutoBackupOnOpen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Unable to load settings: $e')),
        data: (state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _RecurringAlarmSection(),
                ),
              ),
              const _SectionTitle('Navigate'),
              Card(
                child: Column(
                  children: [
                    _NavTile(
                      icon: Icons.home_outlined,
                      label: 'Home',
                      onTap: () => context.go(RouteNames.home),
                    ),
                    const Divider(height: 1),
                    _NavTile(
                      icon: Icons.menu_book_outlined,
                      label: 'Subjects',
                      onTap: () => context.push(RouteNames.subjects),
                    ),
                    const Divider(height: 1),
                    _NavTile(
                      icon: Icons.calendar_month_outlined,
                      label: 'Timetable',
                      onTap: () => context.go(RouteNames.timetable),
                    ),
                    const Divider(height: 1),
                    _NavTile(
                      icon: Icons.event_note_outlined,
                      label: 'Events',
                      onTap: () => context.push(RouteNames.events),
                    ),
                    const Divider(height: 1),
                    _NavTile(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Attendance',
                      onTap: () => context.go(RouteNames.attendance),
                    ),
                    const Divider(height: 1),
                    _NavTile(
                      icon: Icons.analytics_outlined,
                      label: 'Marks',
                      onTap: () => context.go(RouteNames.marks),
                    ),
                    const Divider(height: 1),
                    _NavTile(
                      icon: Icons.apps_rounded,
                      label: 'More',
                      onTap: () => context.go(RouteNames.more),
                    ),
                  ],
                ),
              ),
              const _SectionTitle('AI Provider'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _AiProviderSection(state: state),
                ),
              ),
              const _SectionTitle('Backup & Sync'),
              Card(
                child: SwitchListTile(
                  title: const Text('Auto backup'),
                  subtitle: Text(
                    state.autoBackupEnabled
                        ? 'Backs up automatically when you open Alfred or this screen'
                        : 'Off — back up manually below',
                  ),
                  value: state.autoBackupEnabled,
                  onChanged: (value) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setAutoBackupEnabled(value);
                  },
                ),
              ),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.backup_outlined),
                      title: const Text('Back up now'),
                      subtitle: Text(
                        state.lastBackupAt == null
                            ? 'No backup yet'
                            : 'Last backup: ${DateFormat('MMM d, y • h:mm a').format(state.lastBackupAt!)}',
                      ),
                      trailing: state.isBackingUp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      onTap: state.isBackingUp
                          ? null
                          : () => _handleBackupNow(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.send_outlined),
                      title: const Text('Send backup'),
                      subtitle: const Text('Share via WhatsApp, email, etc.'),
                      onTap: () => _handleSendBackup(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore_outlined),
                      title: const Text('Restore backup'),
                      subtitle: const Text('Choose from your saved backups'),

                      // AFTER - use local variable
                      trailing: _localRestoring
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      onTap: _localRestoring
                          ? null
                          : () => _showBackupPicker(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleBackupNow(BuildContext context) async {
    try {
      final file = await ref
          .read(settingsControllerProvider.notifier)
          .backupNow();
      if (!mounted || file == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup saved: ${file.path}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  Future<void> _handleSendBackup(BuildContext context) async {
    try {
      final controller = ref.read(settingsControllerProvider.notifier);
      final file = await controller.backupNow();
      if (file == null) return;
      await controller.shareBackup(file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to share backup: $e')));
    }
  }

  // ... build method same, but change the restore tile to:
  // trailing: _localRestoring ? CircularProgressIndicator : null
  // onTap: _localRestoring ? null : () => _showBackupPicker(context),

  Future<void> _restoreFromFile(BuildContext context, File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore backup?'),
        content: Text(
          'This will replace all data with:\n${file.uri.pathSegments.last}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore & Restart'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _localRestoring = true);

    try {
      // This closes DB and copies file - it will take 2-5 seconds
      final restored = await ref
          .read(settingsControllerProvider.notifier)
          .restoreFromFile(file);

      if (!mounted) return;

      if (restored) {
        // AUTO RESTART FOR WINDOWS
        await _restartWindowsApp();
      } else {
        setState(() => _localRestoring = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Restore failed')));
      }
    } catch (e) {
      debugPrint('RESTORE ERROR: $e');
      if (!mounted) return;
      setState(() => _localRestoring = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  Future<void> _restartWindowsApp() async {
    try {
      if (Platform.isWindows) {
        // Get current exe path
        final exePath = Platform.resolvedExecutable;
        debugPrint('Restarting: $exePath');

        // Start new instance
        await Process.start(exePath, [], mode: ProcessStartMode.detached);

        // Small delay to let new process start
        await Future.delayed(const Duration(milliseconds: 500));

        // Now close current
        exit(0);
      } else {
        // Mobile - just show dialog
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => AlertDialog(
            title: const Text('Restore complete'),
            content: const Text('Please close and reopen Alfred.'),
            actions: [
              FilledButton(
                onPressed: () => exit(0),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Restart failed: $e');
      // Fallback: just exit, user will open manually
      exit(0);
    }
  }

  Future<void> _showBackupPicker(BuildContext context) async {
    final backups = await ref
        .read(settingsControllerProvider.notifier)
        .listAvailableBackups();
    if (!mounted) return;

    final chosen = await showModalBottomSheet<dynamic>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your backups',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (backups.isEmpty)
                  const Text('No backups found')
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: backups.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final file = backups[index];
                        return ListTile(
                          title: Text(file.uri.pathSegments.last),
                          onTap: () => Navigator.pop(context, file),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, 'browse'),
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Choose a different file'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (chosen == 'browse') {
      await _pickAndRestoreFile(context);
      return;
    }
    if (chosen is File) {
      await _restoreFromFile(context, chosen);
    }
  }

  Future<void> _pickAndRestoreFile(BuildContext context) async {
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['alfredbackup', 'zip'],
      );
      if (files.isEmpty) return;
      final picked = files.first;
      File fileToRestore;

      try {
        final data = await picked.readAsBytes();
        final tempDir = await Directory.systemTemp.createTemp(
          'alfred_restore_',
        );
        final tempFile = File('${tempDir.path}/${picked.name}');
        await tempFile.writeAsBytes(data, flush: true);
        fileToRestore = tempFile;
      } catch (_) {
        final path = picked.path;
        if (path == null) return;
        fileToRestore = File(path);
      }
      await _restoreFromFile(context, fileToRestore);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Picker failed: $e')));
    }
  }

  // ... keep your other methods _handleBackupNow, _handleSendBackup same
}

class _RecurringAlarmSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RecurringAlarmSection> createState() =>
      _RecurringAlarmSectionState();
}

class _RecurringAlarmSectionState
    extends ConsumerState<_RecurringAlarmSection> {
  final _service = RecurringAlarmService();
  bool _enabled = false;
  int _interval = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _service.isEnabled();
    final interval = await _service.getIntervalMinutes();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _interval = interval;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Focus check-ins'),
          subtitle: Text(_enabled ? 'Every $_interval minutes' : 'Off'),
          value: _enabled,
          onChanged: (value) async {
            if (value) {
              await _service.start(_interval);
            } else {
              await _service.stop();
            }
            setState(() => _enabled = value);
          },
        ),
        if (_enabled)
          Slider(
            min: 5,
            max: 60,
            divisions: 11,
            value: _interval.toDouble(),
            label: '$_interval min',
            onChanged: (value) => setState(() => _interval = value.round()),
            onChangeEnd: (value) => _service.start(value.round()),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _AiProviderSection extends ConsumerStatefulWidget {
  final SettingsState state;
  const _AiProviderSection({required this.state});
  @override
  ConsumerState<_AiProviderSection> createState() => _AiProviderSectionState();
}

class _AiProviderSectionState extends ConsumerState<_AiProviderSection> {
  late final TextEditingController _keyController;
  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.state.aiApiKey ?? '');
  }

  @override
  void didUpdateWidget(covariant _AiProviderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.aiProvider != widget.state.aiProvider ||
        oldWidget.state.aiApiKey != widget.state.aiApiKey) {
      final newKey = widget.state.aiApiKey ?? '';
      if (_keyController.text != newKey) _keyController.text = newKey;
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(settingsControllerProvider.notifier);
    final provider = widget.state.aiProvider;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<AiProvider>(
          initialValue: provider,
          decoration: const InputDecoration(
            labelText: 'Provider',
            border: OutlineInputBorder(),
          ),
          items: AiProvider.values
              .map(
                (p) => DropdownMenuItem(value: p, child: Text(p.displayName)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) controller.setAiProvider(value);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: widget.state.aiModel,
          decoration: const InputDecoration(
            labelText: 'Model',
            border: OutlineInputBorder(),
          ),
          items: provider.availableModels
              .map((m) => DropdownMenuItem(value: m.id, child: Text(m.label)))
              .toList(),
          onChanged: (value) {
            if (value != null) controller.setAiModel(value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _keyController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: '${provider.displayName} API Key',
            border: const OutlineInputBorder(),
            helperText: 'Get a free key at ${provider.apiKeyHelpUrl}',
            helperMaxLines: 2,
          ),
          onSubmitted: (value) => controller.setAiApiKey(value.trim()),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => controller.setAiApiKey(_keyController.text.trim()),
            child: const Text('Save key'),
          ),
        ),
      ],
    );
  }
}
