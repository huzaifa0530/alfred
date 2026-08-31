
import 'dart:io';
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
  return 'Alfred_Backup_$stamp.alfredbackup'; // was .zip
}
  Future<void> _addDirectoryToArchive({
    required Archive archive,
    required Directory directory,
    required String archivePrefix,
  }) async {
    if (!await directory.exists()) return;

    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        final relative = p.relative(entity.path, from: directory.path);
        final bytes = await entity.readAsBytes();
        archive.addFile(
          ArchiveFile('$archivePrefix/$relative', bytes.length, bytes),
        );
      }
    }
  }

  /// Zips the database + every image/file/audio attachment, saves it
  /// into [backupDestinationDir], and returns the created file.
  Future<File> createBackup() async {
    final dbFile = await _dbFile();
    final destDir = await backupDestinationDir();

    final archive = Archive();

    if (await dbFile.exists()) {
      final bytes = await dbFile.readAsBytes();
      archive.addFile(ArchiveFile('database/$_dbFileName', bytes.length, bytes));
    }

    await _addDirectoryToArchive(
      archive: archive,
      directory: await AppStorage.imagesDirectory(),
      archivePrefix: 'attachments/images',
    );
    await _addDirectoryToArchive(
      archive: archive,
      directory: await AppStorage.filesDirectory(),
      archivePrefix: 'attachments/files',
    );
    await _addDirectoryToArchive(
      archive: archive,
      directory: await AppStorage.audioDirectory(),
      archivePrefix: 'attachments/audio',
    );

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw Exception('Failed to encode backup archive.');
    }

    final outFile = File(p.join(destDir.path, _timestampedFileName()));
    await outFile.writeAsBytes(zipBytes, flush: true);

    return outFile;
  }

  /// Overwrites the current db + attachments with the contents of
  /// [zipFile]. Caller must close the live db connection first (see
  /// SettingsController.restoreFromPickedFile) — on Windows the file
  /// stays locked while the app holds it open.
  Future<void> restoreBackup(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

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

    for (final entry in archive) {
      if (!entry.isFile) continue;

      final content = entry.content as List<int>;

      if (entry.name.startsWith('database/')) {
        final target = File(p.join(appSupportDir.path, _dbFileName));
        await target.writeAsBytes(content, flush: true);
      } else if (entry.name.startsWith('attachments/images/')) {
        final relative = entry.name.substring('attachments/images/'.length);
        final target = File(p.join(imagesDir.path, relative));
        await target.create(recursive: true);
        await target.writeAsBytes(content, flush: true);
      } else if (entry.name.startsWith('attachments/files/')) {
        final relative = entry.name.substring('attachments/files/'.length);
        final target = File(p.join(filesDir.path, relative));
        await target.create(recursive: true);
        await target.writeAsBytes(content, flush: true);
      } else if (entry.name.startsWith('attachments/audio/')) {
        final relative = entry.name.substring('attachments/audio/'.length);
        final target = File(p.join(audioDir.path, relative));
        await target.create(recursive: true);
        await target.writeAsBytes(content, flush: true);
      }
    }
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





