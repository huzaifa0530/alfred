import 'dart:io';
import 'dart:isolate';

import 'package:alfred/core/storage/app_stoarge.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupService {
  static const _dbFileName = 'alfred.sqlite';
  static const _backupFolderName = 'Alfred Backups';

  Future<Directory> _appSupportDir() => getApplicationSupportDirectory();

  Future<File> _dbFile() async {
    final dir = await _appSupportDir();
    return File(p.join(dir.path, _dbFileName));
  }

  /// Returns a genuinely user-visible folder — the real public Downloads
  /// folder on Android/Windows, falling back to app documents only where
  /// no visible location exists (rare).
  Future<Directory> backupDestinationDir() async {
    Directory backupDir;

    if (Platform.isAndroid) {
      // The real public Downloads path — visible in any file manager,
      // unlike path_provider's app-scoped getDownloadsDirectory().
      backupDir = Directory('/storage/emulated/0/Download/$_backupFolderName');
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final base = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      backupDir = Directory(p.join(base.path, _backupFolderName));
    } else {
      final base = await getApplicationDocumentsDirectory();
      backupDir = Directory(p.join(base.path, _backupFolderName));
    }

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  String _timestampedFileName() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp =
        '${now.year}-${two(now.month)}-${two(now.day)}_${two(now.hour)}-${two(now.minute)}-${two(now.second)}';
    return 'Alfred_Backup_$stamp.alfredbackup';
  }

  /// Reads every file under [directory] into memory, keyed by its
  /// archive path. Pure I/O — runs on the main isolate (fast), the
  /// actual zip compression happens later in a background isolate.
  Future<Map<String, List<int>>> _collectDirectoryFiles({
    required Directory directory,
    required String archivePrefix,
  }) async {
    final result = <String, List<int>>{};
    if (!await directory.exists()) return result;

    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final relative = p.relative(entity.path, from: directory.path).replaceAll('\\', '/');
        result['$archivePrefix/$relative'] = await entity.readAsBytes();
      }
    }
    return result;
  }

  /// Zips the database + every image/file/audio attachment, saves it
  /// into [backupDestinationDir], and returns the created file.
  ///
  /// The actual zip compression runs in a background isolate via
  /// [Isolate.run] so large attachment sets don't freeze the UI thread
  /// (this was the cause of the restore/backup "stuck loading" bug).
  Future<File> createBackup() async {
    final dbFile = await _dbFile();
    final destDir = await backupDestinationDir();

    final entries = <String, List<int>>{};

    if (await dbFile.exists()) {
      entries['database/$_dbFileName'] = await dbFile.readAsBytes();
    }

    entries.addAll(await _collectDirectoryFiles(
      directory: await AppStorage.imagesDirectory(),
      archivePrefix: 'attachments/images',
    ));
    entries.addAll(await _collectDirectoryFiles(
      directory: await AppStorage.filesDirectory(),
      archivePrefix: 'attachments/files',
    ));
    entries.addAll(await _collectDirectoryFiles(
      directory: await AppStorage.audioDirectory(),
      archivePrefix: 'attachments/audio',
    ));

    final zipBytes = await Isolate.run(() => _encodeZip(entries));

    final outFile = File(p.join(destDir.path, _timestampedFileName()));
    await outFile.writeAsBytes(zipBytes, flush: true);

    return outFile;
  }

  /// Runs inside the background isolate spawned by [Isolate.run] in
  /// [createBackup]. Must be static (or top-level) — closures over
  /// instance state can't cross isolates.
  static List<int> _encodeZip(Map<String, List<int>> entries) {
    final archive = Archive();
    entries.forEach((name, bytes) {
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw Exception('Failed to encode backup archive.');
    }
    return zipBytes;
  }

  /// Overwrites the current db + attachments with the contents of
  /// [zipFile]. Caller must close the live db connection first (see
  /// SettingsController.restoreFromPickedFile) — on Windows the file
  /// stays locked while the app holds it open.
  ///
  /// Decompression runs in a background isolate for the same reason
  /// as [createBackup].
  Future<void> restoreBackup(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final decoded = await Isolate.run(() => _decodeZip(bytes));

    final appSupportDir = await _appSupportDir();
    final imagesDir = await AppStorage.imagesDirectory();
    final filesDir = await AppStorage.filesDirectory();
    final audioDir = await AppStorage.audioDirectory();

    for (final dir in [imagesDir, filesDir, audioDir]) {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      await dir.create(recursive: true);
    }

    for (final entry in decoded.entries) {
      final name = entry.key;
      final content = entry.value;

      File? target;
      if (name.startsWith('database/')) {
        target = File(p.join(appSupportDir.path, _dbFileName));
      } else if (name.startsWith('attachments/images/')) {
        target = File(p.join(imagesDir.path, name.substring('attachments/images/'.length)));
      } else if (name.startsWith('attachments/files/')) {
        target = File(p.join(filesDir.path, name.substring('attachments/files/'.length)));
      } else if (name.startsWith('attachments/audio/')) {
        target = File(p.join(audioDir.path, name.substring('attachments/audio/'.length)));
      }

      if (target != null) {
        await target.create(recursive: true);
        await target.writeAsBytes(content, flush: true);
      }
    }
  }

  /// Runs inside the background isolate spawned by [Isolate.run] in
  /// [restoreBackup]. Must be static (or top-level).
  static Map<String, List<int>> _decodeZip(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    return {
      for (final e in archive)
        if (e.isFile) e.name: e.content as List<int>,
    };
  }

  Future<List<File>> listBackups() async {
    final dir = await backupDestinationDir();
    if (!await dir.exists()) return [];

    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.alfredbackup'))
        .cast<File>()
        .toList();

    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified)); // newest first
    return files;
  }
}