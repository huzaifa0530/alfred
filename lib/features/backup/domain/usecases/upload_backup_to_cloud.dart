// upload_backup_to_cloud.dart
import 'dart:io';

import 'package:alfred/core/firebase/dynamic_firebase_app.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UploadBackupToCloud {
  final DynamicFirebaseApp firebaseApp;

  UploadBackupToCloud(this.firebaseApp);

  Future<void> call(File localBackupFile) async {
    final app = firebaseApp.currentApp; // already connected
    final uid = FirebaseAuth.instanceFor(app: app).currentUser!.uid;
    final storage = FirebaseStorage.instanceFor(app: app);

    final timestamp = DateTime.now().toUtc().toIso8601String();
    final ref = storage.ref('backups/$uid/backup_$timestamp.zip');

    await ref.putFile(localBackupFile);
    await _pruneOldBackups(storage, uid, keepLatest: 7);
  }

  Future<void> _pruneOldBackups(FirebaseStorage storage, String uid, {required int keepLatest}) async {
    final list = await storage.ref('backups/$uid').listAll();
    final sorted = list.items..sort((a, b) => b.name.compareTo(a.name)); // ISO timestamps sort lexically
    for (final old in sorted.skip(keepLatest)) {
      await old.delete();
    }
  }
}