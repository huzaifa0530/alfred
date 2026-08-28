import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/mark.dart';
import '../../domain/entities/mark_component.dart';

import 'marks_providers.dart';

class MarksController {
  final Ref ref;

  MarksController(this.ref);

  // ============================================================
  // DEFAULT TEMPLATE
  // ============================================================

  /// Standard grading breakdown applied to every new subject.
  /// Total = 100 marks. Fully editable/deletable afterwards —
  /// this is just a starting point, not a fixed rule.
  static const List<_DefaultComponentSpec> _defaultTemplate = [
    _DefaultComponentSpec(name: 'Quiz 1', type: 'quiz', maxMarks: 5),
    _DefaultComponentSpec(name: 'Quiz 2', type: 'quiz', maxMarks: 5),
    _DefaultComponentSpec(name: 'Assignment 1', type: 'assignment', maxMarks: 5),
    _DefaultComponentSpec(name: 'Assignment 2', type: 'assignment', maxMarks: 5),
    _DefaultComponentSpec(name: 'Midterm', type: 'midterm', maxMarks: 20),
    _DefaultComponentSpec(name: 'Final', type: 'final', maxMarks: 40),
    _DefaultComponentSpec(name: 'Project', type: 'project', maxMarks: 15),
    _DefaultComponentSpec(
      name: 'Class Participation',
      type: 'performance',
      maxMarks: 5,
    ),
  ];

  /// Creates the default component set for [subjectId].
  /// Safe to call even if some components already exist — it just
  /// adds the template on top; it does not check for duplicates,
  /// so only call this for a subject that has none yet.
  Future<void> createDefaultComponents(int subjectId) async {
    final now = DateTime.now();

    for (var i = 0; i < _defaultTemplate.length; i++) {
      final spec = _defaultTemplate[i];

      final component = MarkComponent(
        id: 0,
        subjectId: subjectId,
        name: spec.name,
        type: spec.type,
        maxMarks: spec.maxMarks,
        sortOrder: i,
        createdAt: now,
      );

      await ref.read(createMarkComponentProvider).call(component);
    }

    _refreshSubject(subjectId);
  }

  // ============================================================
  // COMPONENT CRUD
  // ============================================================

  Future<int> createComponent(MarkComponent component) async {
    final id = await ref.read(createMarkComponentProvider).call(component);

    _refreshSubject(component.subjectId);

    return id;
  }

  Future<bool> updateComponent(MarkComponent component) async {
    final result = await ref.read(updateMarkComponentProvider).call(component);

    _refreshSubject(component.subjectId);

    return result;
  }

  Future<void> deleteComponent(MarkComponent component) async {
    await ref.read(deleteMarkComponentProvider).call(component.id);

    _refreshSubject(component.subjectId);
  }

  // ============================================================
  // SAVE MARK
  // ============================================================

  Future<void> saveMark(Mark mark) async {
    await ref.read(saveMarkProvider).call(mark);

    _refreshSubject(mark.subjectId);
  }

  // ============================================================
  // REFRESH
  // ============================================================

  void _refreshSubject(int subjectId) {
    ref.invalidate(subjectMarksProvider(subjectId));
    ref.invalidate(subjectMarkComponentsProvider(subjectId));
    ref.invalidate(marksProvider);
  }
}

class _DefaultComponentSpec {
  final String name;
  final String type;
  final double maxMarks;

  const _DefaultComponentSpec({
    required this.name,
    required this.type,
    required this.maxMarks,
  });
}

// ============================================================
// PROVIDER
// ============================================================

final marksControllerProvider = Provider<MarksController>((ref) {
  return MarksController(ref);
});