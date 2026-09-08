import 'package:flutter/material.dart';

class NoteAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const NoteAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

Future<void> showNoteActionsSheet(
  BuildContext context, {
  required List<NoteAction> actions,
}) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: actions.map((action) {
            final color = action.isDestructive ? Colors.red : null;
            return ListTile(
              leading: Icon(action.icon, color: color),
              title: Text(action.label, style: TextStyle(color: color)),
              onTap: () {
                Navigator.pop(context);
                action.onTap();
              },
            );
          }).toList(),
        ),
      );
    },
  );
}