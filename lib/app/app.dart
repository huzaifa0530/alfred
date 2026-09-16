// app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../features/backup/backup_providers.dart';
import '../features/sharing/share_intent_service.dart';   // <-- add

class AlfredApp extends ConsumerStatefulWidget {
  const AlfredApp({super.key});

  @override
  ConsumerState<AlfredApp> createState() => _AlfredAppState();
}

class _AlfredAppState extends ConsumerState<AlfredApp>
    with WidgetsBindingObserver {
  final _shareIntentService = ShareIntentService();          // <-- add

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appCloudBackupBootstrapProvider).run();
      _shareIntentService.init();                            // <-- add
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shareIntentService.dispose();                            // <-- add
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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