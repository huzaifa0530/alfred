import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/firebase/dynamic_firebase_app.dart';
import 'backup_service.dart';

class CloudBackupInfo {
  final String id;
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
  static const _chunkSize = 700 * 1024;

  final DynamicFirebaseApp firebaseApp;
  final BackupService localBackupService;

  CloudBackupService({
    required this.firebaseApp,
    required this.localBackupService,
  });

  String get _uid {
    if (!firebaseApp.isConnected) {
      throw StateError(
        'Firebase is not connected.',
      );
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError(
        'No authenticated Firebase user.',
      );
    }

    return user.uid;
  }

  FirebaseFirestore get _firestore {
    if (!firebaseApp.isConnected) {
      throw StateError(
        'Firebase is not connected.',
      );
    }

    return FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> _backupsCollection() {
    return _firestore
        .collection('backups')
        .doc(_uid)
        .collection('items');
  }

  Future<void> syncNow({int keepLatest = 5}) async {
    debugPrint('========================================');
    debugPrint('CLOUD SYNC: START');

    try {
      debugPrint('CLOUD SYNC: Checking Firebase connection...');

      if (!firebaseApp.isConnected) {
        throw StateError(
          'Firebase is not connected. '
          'Connect Firebase before syncing.',
        );
      }

      debugPrint('CLOUD SYNC: Firebase connected');

      debugPrint(
        'CLOUD SYNC: Firebase app = ${firebaseApp.currentApp.name}',
      );

      debugPrint(
        'CLOUD SYNC: Firebase project = '
        '${firebaseApp.currentApp.options.projectId}',
      );

      debugPrint(
        'CLOUD SYNC: Current UID = $_uid',
      );

      debugPrint('CLOUD SYNC: Creating local backup...');

      final backupFile =
          await localBackupService.createBackup();

      debugPrint('CLOUD SYNC: Local backup created');

      final bytes = await backupFile.readAsBytes();

      final fileName = p.basename(backupFile.path);

      debugPrint('CLOUD SYNC: File = ${backupFile.path}');
      debugPrint('CLOUD SYNC: File name = $fileName');
      debugPrint('CLOUD SYNC: File size = ${bytes.length} bytes');

      final chunks = <String>[];

      for (var i = 0; i < bytes.length; i += _chunkSize) {
        final end = (i + _chunkSize < bytes.length)
            ? i + _chunkSize
            : bytes.length;

        chunks.add(
          base64Encode(
            bytes.sublist(i, end),
          ),
        );
      }

      debugPrint(
        'CLOUD SYNC: Chunks created = ${chunks.length}',
      );

      final backupId = DateTime.now()
          .toUtc()
          .toIso8601String()
          .replaceAll(RegExp(r'[:.]'), '-');

      debugPrint('CLOUD SYNC: Backup ID = $backupId');

      final docRef =
          _backupsCollection().doc(backupId);

      debugPrint('CLOUD SYNC: Creating backup document...');

      await docRef.set({
        'fileName': fileName,
        'uploadedAt': FieldValue.serverTimestamp(),
        'chunkCount': chunks.length,
        'totalBytes': bytes.length,
        'complete': false,
      });

      debugPrint('CLOUD SYNC: Backup document created');

      final batchWriter = _firestore.batch();

      for (var i = 0; i < chunks.length; i++) {
        batchWriter.set(
          docRef.collection('chunks').doc('$i'),
          {
            'data': chunks[i],
          },
        );
      }

      debugPrint('CLOUD SYNC: Uploading chunks...');

      await batchWriter.commit();

      debugPrint('CLOUD SYNC: Chunks uploaded');

      await docRef.update({
        'complete': true,
      });

      debugPrint('CLOUD SYNC: Backup marked complete');

      await _pruneOldBackups(
        keepLatest: keepLatest,
      );

      debugPrint('CLOUD SYNC: SUCCESS');
      debugPrint('========================================');
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('CLOUD SYNC: FAILED');
      debugPrint('ERROR TYPE: ${e.runtimeType}');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE:');
      debugPrint(stackTrace.toString());
      debugPrint('========================================');

      rethrow;
    }
  }

  Future<List<CloudBackupInfo>> listCloudBackups() async {
    final snapshot = await _backupsCollection()
        .where(
          'complete',
          isEqualTo: true,
        )
        .orderBy(
          'uploadedAt',
          descending: true,
        )
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return CloudBackupInfo(
        id: doc.id,
        fileName: data['fileName'] as String,
        uploadedAt:
            (data['uploadedAt'] as Timestamp).toDate(),
        chunkCount:
            data['chunkCount'] as int,
        totalBytes:
            data['totalBytes'] as int,
      );
    }).toList();
  }

  Future<File> downloadCloudBackup(
    CloudBackupInfo info,
  ) async {
    final docRef =
        _backupsCollection().doc(info.id);

    final buffer = BytesBuilder();

    for (var i = 0; i < info.chunkCount; i++) {
      final chunkDoc = await docRef
          .collection('chunks')
          .doc('$i')
          .get();

      final data =
          chunkDoc.data()!['data'] as String;

      buffer.add(
        base64Decode(data),
      );
    }

    final tempDir =
        await getTemporaryDirectory();

    final tempFile = File(
      p.join(
        tempDir.path,
        info.fileName,
      ),
    );

    await tempFile.writeAsBytes(
      buffer.takeBytes(),
      flush: true,
    );

    return tempFile;
  }

  Future<void> _pruneOldBackups({
    required int keepLatest,
  }) async {
    final backups =
        await listCloudBackups();

    for (final old
        in backups.skip(keepLatest)) {
      await _deleteBackup(old.id);
    }
  }

  Future<void> _deleteBackup(
    String backupId,
  ) async {
    final docRef =
        _backupsCollection().doc(backupId);

    final chunks = await docRef
        .collection('chunks')
        .get();

    final batch = _firestore.batch();

    for (final chunk
        in chunks.docs) {
      batch.delete(
        chunk.reference,
      );
    }

    batch.delete(docRef);

    await batch.commit();
  }
}