import 'dart:io';

import 'package:alfred/app/router/route_names.dart';
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
                      subtitle: const Text('Choose a .zip backup to restore'),
                      trailing: state.isRestoring
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      onTap: state.isRestoring
                          ? null
                          : () => _handleRestore(context),
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

  Future<void> _handleRestore(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
          'This replaces all current notes, attachments and marks with '
          'the contents of the backup you choose. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final restored = await ref
          .read(settingsControllerProvider.notifier)
          .restoreFromPickedFile();
      if (!mounted || !restored) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Restore complete'),
          content: const Text(
            'Please close Alfred completely and reopen it for the restored data to load.',
          ),
          actions: [
            FilledButton(
              onPressed: () => exit(0),
              child: const Text('Close Alfred'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
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
