import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/mark_component.dart';
import '../controllers/marks_controller.dart';

class EditMarkComponentSheet extends ConsumerStatefulWidget {
  final MarkComponent component;
  const EditMarkComponentSheet({super.key, required this.component});

  @override
  ConsumerState<EditMarkComponentSheet> createState() => _EditMarkComponentSheetState();
}

class _EditMarkComponentSheetState extends ConsumerState<EditMarkComponentSheet> {
  late TextEditingController nameCtrl;
  late TextEditingController maxCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.component.name);
    maxCtrl = TextEditingController(text: widget.component.maxMarks.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 12),
        TextField(controller: maxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Marks')),
        const SizedBox(height: 20),
        Row(children: [
          IconButton(
            onPressed: () async {
              await ref.read(marksControllerProvider).deleteComponent(widget.component);
              if (mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () async {
              final updated = widget.component.copyWith(
                name: nameCtrl.text.trim(),
                maxMarks: double.tryParse(maxCtrl.text) ?? widget.component.maxMarks,
              );
              await ref.read(marksControllerProvider).updateComponent(updated);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ]),
      ]),
    );
  }
}