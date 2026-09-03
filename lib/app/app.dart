// app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../features/backup/backup_providers.dart';

class AlfredApp extends ConsumerStatefulWidget {
  const AlfredApp({super.key});

  @override
  ConsumerState<AlfredApp> createState() => _AlfredAppState();
}

class _AlfredAppState extends ConsumerState<AlfredApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Fire-and-forget: runs after the first frame, never blocks
    // startup, and swallows its own errors (see AppCloudBackupBootstrap).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appCloudBackupBootstrapProvider).run();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Also check on resume — covers the "app stayed open across
    // midnight" and "reopened after being backgrounded for days" cases,
    // not just cold start.
    if (state == AppLifecycleState.resumed) {
      ref.read(appCloudBackupBootstrapProvider).run();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Alfred.',
      theme: AppTheme.dark(),
      routerConfig: AppRouter.router,
    );
  }
}