// features/sharing/share_intent_service.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../app/router/app_router.dart';
import 'subject_picker_sheet.dart';

class SharedPayload {
  const SharedPayload({required this.text, required this.files});
  final String text;
  final List<File> files;

  bool get isEmpty => text.trim().isEmpty && files.isEmpty;
}

class ShareIntentService {
  StreamSubscription<List<SharedMediaFile>>? _sub;
  bool _handling = false;

  void init() {
    _sub = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handle,
      onError: (e) => debugPrint('SHARE STREAM ERROR: $e'),
    );

    ReceiveSharingIntent.instance.getInitialMedia().then((media) async {
      if (media.isEmpty) return;
      await Future.delayed(const Duration(milliseconds: 100));
      _handle(media);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void dispose() => _sub?.cancel();

  Future<void> _handle(List<SharedMediaFile> media) async {
    if (media.isEmpty || _handling) return;
    _handling = true;

    try {
      final textParts = <String>[];
      final files = <File>[];

      for (final item in media) {
        if (item.type == SharedMediaType.text ||
            item.type == SharedMediaType.url) {
          textParts.add(item.path);
        } else {
          final file = File(item.path);
          if (await file.exists()) files.add(file);
        }
      }

      final payload = SharedPayload(text: textParts.join('\n\n'), files: files);
      if (payload.isEmpty) return;

      final context = AppRouter.rootNavigatorKey.currentContext;
      if (context == null) return;

      final subject = await showSubjectPicker(context);
      if (subject == null) return;
      if (!context.mounted) return;

      context.push(
        '/subjects/${subject.id}?name=${Uri.encodeComponent(subject.name)}',
        extra: {
          'initialText': payload.text,
          'initialAttachments': payload.files,
        },
      );
    } finally {
      _handling = false;
    }
  }
}
