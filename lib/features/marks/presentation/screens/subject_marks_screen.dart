
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/mark.dart';
import '../../domain/entities/mark_component.dart';
import '../controllers/marks_controller.dart';
import '../controllers/marks_providers.dart';

class SubjectMarksScreen extends ConsumerWidget {
  final int subjectId;
  final String subjectName;

  const SubjectMarksScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final componentsAsync =
        ref.watch(subjectMarkComponentsProvider(subjectId));

    final marksAsync = ref.watch(subjectMarksProvider(subjectId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          subjectName,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddComponentSheet(context, ref);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Assessment'),
      ),

      body: SafeArea(
        child: componentsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),

          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load assessments.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          data: (components) {
            if (components.isEmpty) {
              return _EmptyComponents(
                onAdd: () {
                  _showAddComponentSheet(context, ref);
                },
              );
            }

            return marksAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),

              error: (error, stack) => Center(
                child: Text(
                  'Unable to load marks.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),

              data: (marks) {
                return _MarksContent(
                  subjectId: subjectId,
                  components: components,
                  marks: marks,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _showAddComponentSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final maxMarksController = TextEditingController();
    String selectedType = 'quiz';

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  8,
                  24,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add assessment',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Assessment name',
                        hintText: 'Example: Quiz 3',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: maxMarksController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Maximum marks',
                        hintText: 'Example: 10',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'quiz',
                          child: Text('Quiz'),
                        ),
                        DropdownMenuItem(
                          value: 'assignment',
                          child: Text('Assignment'),
                        ),
                        DropdownMenuItem(
                          value: 'midterm',
                          child: Text('Midterm'),
                        ),
                        DropdownMenuItem(
                          value: 'final',
                          child: Text('Final'),
                        ),
                        DropdownMenuItem(
                          value: 'project',
                          child: Text('Project'),
                        ),
                        DropdownMenuItem(
                          value: 'performance',
                          child: Text('Performance'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final maxMarks =
                              double.tryParse(maxMarksController.text.trim());

                          if (name.isEmpty ||
                              maxMarks == null ||
                              maxMarks <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter a valid name and maximum marks.',
                                ),
                              ),
                            );
                            return;
                          }

                          final componentsState = ref.read(
                            subjectMarkComponentsProvider(subjectId),
                          );
                          final nextOrder = componentsState.maybeWhen(
                            data: (components) => components.length,
                            orElse: () => 0,
                          );

                          final component = MarkComponent(
                            id: 0,
                            subjectId: subjectId,
                            name: name,
                            type: selectedType,
                            maxMarks: maxMarks,
                            sortOrder: nextOrder,
                            createdAt: DateTime.now(),
                          );

                          try {
                            await ref
                                .read(marksControllerProvider)
                                .createComponent(component);

                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          } catch (e) {
                            if (sheetContext.mounted) {
                              ScaffoldMessenger.of(sheetContext)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to add assessment: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add assessment'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      maxMarksController.dispose();
    }
  }
}

class _MarksContent extends ConsumerWidget {
  final int subjectId;
  final List<MarkComponent> components;
  final List<Mark> marks;

  const _MarksContent({
    required this.subjectId,
    required this.components,
    required this.marks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final markMap = <int, Mark>{
      for (final mark in marks) mark.componentId: mark,
    };

    double totalObtained = 0;
    double totalMaximum = 0;

    for (final component in components) {
      final mark = markMap[component.id];

      totalMaximum += component.maxMarks;

      if (mark?.obtainedMarks != null) {
        totalObtained += mark!.obtainedMarks!;
      }
    }

    final percentage = totalMaximum == 0
        ? null
        : (totalObtained / totalMaximum) * 100;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: _SummaryCard(
              obtained: totalObtained,
              maximum: totalMaximum,
              percentage: percentage,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              'Assessments',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          sliver: SliverList.separated(
            itemCount: components.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final component = components[index];
              final mark = markMap[component.id];

              return _MarkComponentTile(
                subjectId: subjectId,
                component: component,
                mark: mark,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double obtained;
  final double maximum;
  final double? percentage;

  const _SummaryCard({
    required this.obtained,
    required this.maximum,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final percentageText = percentage == null
        ? '—'
        : '${percentage!.toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                percentageText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current marks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${_format(obtained)} / ${_format(maximum)} marks',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }
}

class _MarkComponentTile extends ConsumerStatefulWidget {
  final int subjectId;
  final MarkComponent component;
  final Mark? mark;

  const _MarkComponentTile({
    required this.subjectId,
    required this.component,
    required this.mark,
  });

  @override
  ConsumerState<_MarkComponentTile> createState() =>
      _MarkComponentTileState();
}

class _MarkComponentTileState
    extends ConsumerState<_MarkComponentTile> {
  late final TextEditingController controller;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(
      text: widget.mark?.obtainedMarks == null
          ? ''
          : _format(widget.mark!.obtainedMarks!),
    );
  }

  @override
  void didUpdateWidget(covariant _MarkComponentTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldValue = oldWidget.mark?.obtainedMarks;
    final newValue = widget.mark?.obtainedMarks;

    if (oldValue != newValue && newValue != null) {
      final formatted = _format(newValue);

      if (controller.text != formatted) {
        controller.text = formatted;
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = controller.text.trim();

    if (text.isEmpty) {
      return;
    }

    final value = double.tryParse(text);

    if (value == null) {
      _showError('Enter a valid number.');
      return;
    }

    if (value < 0 || value > widget.component.maxMarks) {
      _showError(
        'Marks must be between 0 and ${_format(widget.component.maxMarks)}.',
      );
      return;
    }

    final current = widget.mark;

    final mark = Mark(
      id: current?.id ?? 0,
      subjectId: widget.subjectId,
      componentId: widget.component.id,
      obtainedMarks: value,
      updatedAt: DateTime.now(),
    );

    setState(() {
      saving = true;
    });

    try {
      await ref.read(marksControllerProvider).saveMark(mark);

      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to save marks.');
      }
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final type = widget.component.type;
    final typeText = type == null || type.isEmpty
        ? null
        : _capitalize(type);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                _iconForType(type),
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.component.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    [
                      if (typeText != null) typeText,
                      'Max ${_format(widget.component.maxMarks)}',
                    ].join(' • '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            SizedBox(
              width: 82,
              child: TextField(
                controller: controller,
                enabled: !saving,
                textAlign: TextAlign.center,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  hintText: '—',
                  suffixText: '/${_format(widget.component.maxMarks)}',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 6),

            IconButton(
              tooltip: 'Save marks',
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
            ),

            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteComponent();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded),
                      SizedBox(width: 10),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteComponent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete assessment?'),
          content: Text(
            'Delete "${widget.component.name}" and its mark?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await ref
          .read(marksControllerProvider)
          .deleteComponent(widget.component);
    } catch (e) {
      if (mounted) {
        _showError('Failed to delete assessment.');
      }
    }
  }

  static String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;

    return value[0].toUpperCase() + value.substring(1);
  }

  static IconData _iconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'quiz':
        return Icons.quiz_outlined;

      case 'assignment':
        return Icons.assignment_outlined;

      case 'midterm':
        return Icons.menu_book_outlined;

      case 'final':
        return Icons.school_outlined;

      case 'project':
        return Icons.work_outline_rounded;

      case 'performance':
        return Icons.star_outline_rounded;

      default:
        return Icons.grade_outlined;
    }
  }
}

class _EmptyComponents extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyComponents({
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(
                Icons.grading_outlined,
                size: 38,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'No assessments yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Add quizzes, assignments, midterm, final, '
              'project or any other assessment.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 22),

            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add assessment'),
            ),
          ],
        ),
      ),
    );
  }
}

