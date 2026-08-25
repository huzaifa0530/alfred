import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'file_storage_service.dart';

final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return const FileStorageService();
});
