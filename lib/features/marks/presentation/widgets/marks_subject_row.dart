import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../subjects/domain/entities/subject.dart';

import '../../domain/entities/mark.dart';
import '../../domain/entities/mark_component.dart';

import '../controllers/marks_controller.dart';

class MarksSubjectRow extends ConsumerWidget {
  final Subject subject;
  final List<MarkComponent> components;
  final List<Mark> marks;

  final double subjectWidth;
  final double componentWidth;

  const MarksSubjectRow({
    super.key,
    required this.subject,
    required this.components,
    required this.marks,
    this.subjectWidth = 150,
    this.componentWidth = 105,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 72,
      child: Row(
        children: [
          // ====================================================
          // SUBJECT NAME
          // ====================================================

          Container(
            width: subjectWidth,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
            ),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.4),
                ),
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.4),
                ),
              ),
            ),
            child: Text(
              subject.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // ====================================================
          // MARK CELLS
          // ====================================================

          ...components.map(
            (component) {
              final mark = _findMark(component.id);

              return _MarkCell(
                width: componentWidth,
                component: component,
                mark: mark,
                subjectId: subject.id,
                onSave: (value) async {
                  final controller =
                      ref.read(marksControllerProvider);

                  final newMark = Mark(
                    id: mark?.id ?? 0,
                    subjectId: subject.id,
                    componentId: component.id,
                    obtainedMarks: value,
                    updatedAt: DateTime.now(),
                  );

                  await controller.saveMark(newMark);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Mark? _findMark(int componentId) {
    for (final mark in marks) {
      if (mark.componentId == componentId) {
        return mark;
      }
    }

    return null;
  }
}


// ============================================================
// MARK CELL
// ============================================================

class _MarkCell extends StatefulWidget {
  final double width;
  final MarkComponent component;
  final Mark? mark;
  final int subjectId;
  final Future<void> Function(double?) onSave;

  const _MarkCell({
    required this.width,
    required this.component,
    required this.mark,
    required this.subjectId,
    required this.onSave,
  });

  @override
  State<_MarkCell> createState() => _MarkCellState();
}

class _MarkCellState extends State<_MarkCell> {
  late final TextEditingController controller;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(
      text: _displayValue(widget.mark?.obtainedMarks),
    );
  }

  @override
  void didUpdateWidget(
    covariant _MarkCell oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final oldValue =
        oldWidget.mark?.obtainedMarks;

    final newValue =
        widget.mark?.obtainedMarks;

    if (oldValue != newValue &&
        !_isFocused()) {
      controller.text = _displayValue(newValue);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasValue = widget.mark?.obtainedMarks != null;

    return Container(
      width: widget.width,
      height: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant
                .withValues(alpha: 0.4),
          ),
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant
                .withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Center(
        child: SizedBox(
          height: 46,
          child: TextField(
            controller: controller,
            enabled: !saving,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d*\.?\d*'),
              ),
            ],
            decoration: InputDecoration(
              hintText: '—',
              filled: true,
              fillColor: hasValue
                  ? theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.35)
                  : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            onSubmitted: (_) => _save(),
            onEditingComplete: _save,
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final raw = controller.text.trim();

    if (raw.isEmpty) {
      await _performSave(null);
      return;
    }

    final value = double.tryParse(raw);

    if (value == null) {
      return;
    }

    if (value < 0) {
      return;
    }

    if (value > widget.component.maxMarks) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Maximum marks are ${_format(widget.component.maxMarks)}.',
            ),
          ),
        );
      }

      controller.text = _displayValue(
        widget.mark?.obtainedMarks,
      );

      return;
    }

    await _performSave(value);
  }

  Future<void> _performSave(double? value) async {
    setState(() {
      saving = true;
    });

    try {
      await widget.onSave(value);
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  bool _isFocused() {
    return FocusManager.instance.primaryFocus
            ?.context
            ?.findAncestorWidgetOfExactType<
                EditableText>() !=
        null;
  }

  String _displayValue(double? value) {
    if (value == null) {
      return '';
    }

    return _format(value);
  }

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }
}