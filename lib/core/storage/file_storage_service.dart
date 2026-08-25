import 'dart:io';

import 'package:alfred/core/storage/app_stoarge.dart';


class FileStorageService {
  const FileStorageService();

  Future<String> saveImage({
    required File source,
    required String fileName,
  }) async {
    final directory =
        await AppStorage.imagesDirectory();

    return _copyFile(
      source: source,
      directory: directory,
      fileName: fileName,
    );
  }

  Future<String> saveFile({
    required File source,
    required String fileName,
  }) async {
    final directory =
        await AppStorage.filesDirectory();

    return _copyFile(
      source: source,
      directory: directory,
      fileName: fileName,
    );
  }

  Future<String> saveAudio({
    required File source,
    required String fileName,
  }) async {
    final directory =
        await AppStorage.audioDirectory();

    return _copyFile(
      source: source,
      directory: directory,
      fileName: fileName,
    );
  }

  Future<String> _copyFile({
    required File source,
    required Directory directory,
    required String fileName,
  }) async {
    final safeName = _sanitizeFileName(fileName);

    final target = File(
      '${directory.path}/$safeName',
    );

    final uniqueTarget =
        await _createUniqueTarget(target);

    final copiedFile =
        await source.copy(uniqueTarget.path);

    return copiedFile.path;
  }

  Future<File> _createUniqueTarget(
    File target,
  ) async {
    if (!await target.exists()) {
      return target;
    }

    final directory = target.parent;
    final name = target.uri.pathSegments.last;

    final dotIndex = name.lastIndexOf('.');

    final baseName = dotIndex == -1
        ? name
        : name.substring(0, dotIndex);

    final extension = dotIndex == -1
        ? ''
        : name.substring(dotIndex);

    var counter = 1;

    while (true) {
      final candidate = File(
        '${directory.path}/'
        '$baseName-$counter$extension',
      );

      if (!await candidate.exists()) {
        return candidate;
      }

      counter++;
    }
  }

  String _sanitizeFileName(String name) {
    final cleaned = name
        .trim()
        .replaceAll(
          RegExp(r'[<>:"/\\|?*]'),
          '_',
        );

    if (cleaned.isEmpty) {
      return 'file';
    }

    return cleaned;
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> exists(String path) {
    return File(path).exists();
  }

  Future<int> getFileSize(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      return 0;
    }

    return file.length();
  }
}