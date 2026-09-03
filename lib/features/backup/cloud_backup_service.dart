// features/backup/cloud_backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/firebase/dynamic_firebase_app.dart';
import 'backup_service.dart';

class CloudBackupInfo {
  final String id; // backup document id (timestamp-based)
  final String fileName;
  final DateTime uploadedAt;
  final int chunkCount;
  final int totalBytes;

  CloudBackupInfo({
    required this.id,
    required this.fileName,
    required this.uploadedAt,
    required this.chunkCount,
    required this.totalBytes,
  });
}

class CloudBackupService {
  static const _chunkSize = 700 * 1024; // ~700KB raw -> ~950KB base64, safely under 1MiB doc cap

  final DynamicFirebaseApp firebaseApp;
  final BackupService localBackupService;

  CloudBackupService({required this.firebaseApp, required this.localBackupService});

  String get _uid => FirebaseAuth.instanceFor(app: firebaseApp.currentApp).currentUser!.uid;

  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(app: firebaseApp.currentApp);

  CollectionReference<Map<String, dynamic>> _backupsCollection() {
    return _firestore.collection('backups').doc(_uid).collection('items');
  }

  /// Creates a local backup (reusing BackupService) and uploads it to
  /// Firestore as base64 chunks. Free-tier Firestore, no billing card.
  Future<void> syncNow({int keepLatest = 5}) async {
    final backupFile = await localBackupService.createBackup();
    final bytes = await backupFile.readAsBytes();
    final fileName = p.basename(backupFile.path);

    final chunks = <String>[];
    for (var i = 0; i < bytes.length; i += _chunkSize) {
      final end = (i + _chunkSize < bytes.length) ? i + _chunkSize : bytes.length;
      chunks.add(base64Encode(bytes.sublist(i, end)));
    }

    final backupId = DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final docRef = _backupsCollection().doc(backupId);

    // Metadata doc first, so a partial-chunk failure doesn't produce a
    // "backup" that looks complete when listed.
    await docRef.set({
      'fileName': fileName,
      'uploadedAt': FieldValue.serverTimestamp(),
      'chunkCount': chunks.length,
      'totalBytes': bytes.length,
      'complete': false,
    });

    final batchWriter = _firestore.batch();
    for (var i = 0; i < chunks.length; i++) {
      batchWriter.set(docRef.collection('chunks').doc('$i'), {'data': chunks[i]});
    }
    await batchWriter.commit();

    await docRef.update({'complete': true});

    await _pruneOldBackups(keepLatest: keepLatest);
  }

  Future<List<CloudBackupInfo>> listCloudBackups() async {
    final snapshot = await _backupsCollection()
        .where('complete', isEqualTo: true)
        .orderBy('uploadedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return CloudBackupInfo(
        id: doc.id,
        fileName: data['fileName'] as String,
        uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
        chunkCount: data['chunkCount'] as int,
        totalBytes: data['totalBytes'] as int,
      );
    }).toList();
  }

  /// Downloads and reassembles [info] into a local temp file. Caller
  /// restores via SettingsController.restoreFromFile (needs the DB
  /// closed first — see BackupService.restoreBackup's Windows note).
  Future<File> downloadCloudBackup(CloudBackupInfo info) async {
    final docRef = _backupsCollection().doc(info.id);

    final buffer = BytesBuilder();
    for (var i = 0; i < info.chunkCount; i++) {
      final chunkDoc = await docRef.collection('chunks').doc('$i').get();
      final data = chunkDoc.data()!['data'] as String;
      buffer.add(base64Decode(data));
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, info.fileName));
    await tempFile.writeAsBytes(buffer.takeBytes(), flush: true);
    return tempFile;
  }

  Future<void> _pruneOldBackups({required int keepLatest}) async {
    final backups = await listCloudBackups();
    for (final old in backups.skip(keepLatest)) {
      await _deleteBackup(old.id);
    }
  }

  Future<void> _deleteBackup(String backupId) async {
    final docRef = _backupsCollection().doc(backupId);
    final chunks = await docRef.collection('chunks').get();
    final batch = _firestore.batch();
    for (final chunk in chunks.docs) {
      batch.delete(chunk.reference);
    }
    batch.delete(docRef);
    await batch.commit();
  }
}