import 'package:flutter/material.dart';

class EventTypeIcon extends StatelessWidget {
  final String type;

  const EventTypeIcon({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;

    switch (type.toLowerCase()) {
      case 'quiz':
        icon = Icons.quiz_outlined;
        break;

      case 'assignment':
        icon = Icons.assignment_outlined;
        break;

      case 'exam':
        icon = Icons.school_outlined;
        break;

      case 'presentation':
        icon = Icons.present_to_all_outlined;
        break;

      case 'project':
        icon = Icons.folder_outlined;
        break;

      default:
        icon = Icons.event_outlined;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Icon(icon),
    );
  }
}