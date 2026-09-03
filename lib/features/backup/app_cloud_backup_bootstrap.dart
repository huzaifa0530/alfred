import 'package:flutter/material.dart';

import '../../core/firebase/firebase_credentials_storage.dart';
import '../../core/firebase/dynamic_firebase_app.dart';
import 'auto_backup_scheduler.dart';

class AppCloudBackupBootstrap {
  final FirebaseCredentialsStorage credentialsStorage;
  final DynamicFirebaseApp firebaseApp;
  final AutoBackupScheduler autoBackupScheduler;

  AppCloudBackupBootstrap({
    required this.credentialsStorage,
    required this.firebaseApp,
    required this.autoBackupScheduler,
  });

  Future<void> run() async {
    debugPrint('========================================');
    debugPrint('CLOUD BOOTSTRAP: START');

    try {
      debugPrint(
        'CLOUD BOOTSTRAP: Reading saved credentials...',
      );

      final creds =
          await credentialsStorage.read();

      if (creds == null) {
        debugPrint(
          'CLOUD BOOTSTRAP: No saved credentials.',
        );
        return;
      }

      debugPrint(
        'CLOUD BOOTSTRAP: Credentials found',
      );

      debugPrint(
        'CLOUD BOOTSTRAP: projectId = '
        '${creds.projectId}',
      );

      debugPrint(
        'CLOUD BOOTSTRAP: Calling Firebase connect...',
      );

      final uid =
          await firebaseApp.connect(creds);

      debugPrint(
        'CLOUD BOOTSTRAP: Firebase connect SUCCESS',
      );

      debugPrint(
        'CLOUD BOOTSTRAP: UID = $uid',
      );

      debugPrint(
        'CLOUD BOOTSTRAP: isConnected = '
        '${firebaseApp.isConnected}',
      );

      debugPrint(
        'CLOUD BOOTSTRAP: Running scheduler...',
      );

      await autoBackupScheduler.runIfDue();

      debugPrint(
        'CLOUD BOOTSTRAP: Scheduler SUCCESS',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'CLOUD BOOTSTRAP: FAILED',
      );

      debugPrint(
        'ERROR TYPE: ${e.runtimeType}',
      );

      debugPrint(
        'ERROR: $e',
      );

      debugPrint(
        'STACK TRACE:',
      );

      debugPrint(stackTrace.toString());
    }

    debugPrint('========================================');
  }
}