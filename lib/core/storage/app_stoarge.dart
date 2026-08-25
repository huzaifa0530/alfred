import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'storage_paths.dart';

class AppStorage {
  const AppStorage._();

  static Future<Directory> rootDirectory() async {
    final directory =
        await getApplicationDocumentsDirectory();

    final root = Directory(
      '${directory.path}/Alfred',
    );

    if (!await root.exists()) {
      await root.create(
        recursive: true,
      );
    }

    return root;
  }

  static Future<Directory>
      attachmentsDirectory() async {
    final root = await rootDirectory();

    final directory = Directory(
      '${root.path}/${StoragePaths.attachments}',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  static Future<Directory>
      imagesDirectory() async {
    final attachments =
        await attachmentsDirectory();

    final directory = Directory(
      '${attachments.path}/${StoragePaths.images}',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  static Future<Directory>
      filesDirectory() async {
    final attachments =
        await attachmentsDirectory();

    final directory = Directory(
      '${attachments.path}/${StoragePaths.files}',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  static Future<Directory>
      audioDirectory() async {
    final attachments =
        await attachmentsDirectory();

    final directory = Directory(
      '${attachments.path}/${StoragePaths.audio}',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }
}