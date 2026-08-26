import 'package:flutter/material.dart';

class AttachmentMenu extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onFile;

  const AttachmentMenu({
    super.key,
    required this.onCamera,
    required this.onGallery,
    required this.onFile,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24,
        ),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant,
                borderRadius:
                    BorderRadius.circular(99),
              ),
            ),

            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add to note',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _AttachmentOption(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: onCamera,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AttachmentOption(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: onGallery,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AttachmentOption(
                    icon: Icons.attach_file_rounded,
                    label: 'File',
                    onTap: onFile,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 20,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}