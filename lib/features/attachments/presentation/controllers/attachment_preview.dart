import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/attachment.dart';

class AttachmentPreview extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback? onDelete;

  const AttachmentPreview({
    super.key,
    required this.attachment,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (attachment.isImage) {
      return _buildImage(context);
    }

    return _buildFile(context);
  }

  Widget _buildImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.file(
            File(attachment.path),
            width: 260,
            height: 190,
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return _missingFile();
            },
          ),

          if (onDelete != null)
            Positioned(
              top: 8,
              right: 8,
              child: _deleteButton(context),
            ),
        ],
      ),
    );
  }

  Widget _buildFile(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.insert_drive_file_outlined,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              attachment.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
              ),
            ),
        ],
      ),
    );
  }

  Widget _deleteButton(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onDelete,
        child: const Padding(
          padding: EdgeInsets.all(7),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _missingFile() {
    return Container(
      width: 260,
      height: 190,
      alignment: Alignment.center,
      color: Colors.black12,
      child: const Icon(
        Icons.broken_image_outlined,
        size: 40,
      ),
    );
  }
}