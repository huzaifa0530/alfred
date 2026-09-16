// lib/features/gpa/presentation/controllers/gpa_providers.dart
import 'package:alfred/features/gpa/domain/smiu_grading.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../marks/presentation/controllers/marks_providers.dart';
import '../../../subjects/presentation/controllers/subjects_controller.dart';
import '../../data/gpa_prefs_service.dart';

final gpaPrefsProvider = Provider((ref) => GpaPrefsService());

final prevCgpaProvider = StateProvider<double>((ref) => 0.0);
final prevCreditsProvider = StateProvider<int>((ref) => 0);

// Load saved on start
final prevDataLoaderProvider = FutureProvider<void>((ref) async {
  final service = ref.read(gpaPrefsProvider);
  final (cgpa, credits) = await service.loadPrevData();
  ref.read(prevCgpaProvider.notifier).state = cgpa;
  ref.read(prevCreditsProvider.notifier).state = credits;
});

class SubjectGpa {
  final int subjectId;
  final String name;
  final String courseCode;
  final double obtained;
  final double max;
  final double percent;
  final SMIUGrade grade;
  final int creditHours;

  SubjectGpa({
    required this.subjectId,
    required this.name,
    required this.courseCode,
    required this.obtained,
    required this.max,
    required this.percent,
    required this.grade,
    required this.creditHours,
  });
  double get qualityPoints => grade.point * creditHours;
}

// Helper to safely get value from AsyncValue without valueOrNull
List<T> _getList<T>(AsyncValue<List<T>> async) {
  return async.maybeWhen(
    data: (value) => value,
    orElse: () => <T>[],
  );
}

final currentSemGpaProvider = Provider<(List<SubjectGpa> list, double sgpa, int totalCredits, double totalQP)>((ref) {
  final subjectsAsync = ref.watch(subjectsControllerProvider);

  final subjects = subjectsAsync.maybeWhen(
    data: (s) => s,
    orElse: () => [],
  );

  if (subjects.isEmpty) {
    return ([], 0.0, 0, 0.0);
  }

  List<SubjectGpa> gpaList = [];
  double totalQP = 0;
  int totalCredits = 0;

  for (var sub in subjects) {
    // This watch is okay now because we are in a normal Provider
    final marksAsync = ref.watch(subjectMarksProvider(sub.id));
    final compsAsync = ref.watch(subjectMarkComponentsProvider(sub.id));

    final marks = _getList(marksAsync);
    final comps = _getList(compsAsync);

    if (comps.isEmpty) continue;

    double obtained = 0;
    double max = 0;
    for (var c in comps) {
      max += c.maxMarks;
      final m = marks.firstWhereOrNull((x) => x.componentId == c.id);
      if (m?.obtainedMarks != null) obtained += m!.obtainedMarks!;
    }
    if (max == 0) continue;

    final percent = (obtained / max) * 100;
    final grade = getGradeFromPercentage(percent);

    // Credit hours: check if Subject has creditHours, else guess
    int credit;
    try {
      credit = (sub as dynamic).creditHours as int;
    } catch (_) {
      final isLab = sub.name.toLowerCase().contains('lab');
      credit = isLab ? 1 : 3;
    }

    final courseCode = RegExp(r'[A-Z]{3}\d{3}').firstMatch(sub.name)?.group(0) ?? sub.name;

    final item = SubjectGpa(
      subjectId: sub.id,
      name: sub.name,
      courseCode: courseCode,
      obtained: obtained,
      max: max,
      percent: percent,
      grade: grade,
      creditHours: credit,
    );
    gpaList.add(item);
    totalQP += item.qualityPoints;
    totalCredits += credit;
  }

  final sgpa = totalCredits == 0 ? 0.0 : totalQP / totalCredits;
  return (gpaList, sgpa, totalCredits, totalQP);
});

final cgpaProvider = Provider<double>((ref) {
  final current = ref.watch(currentSemGpaProvider);
  final (list, sgpa, currCredits, currQP) = current;

  if (list.isEmpty && currCredits == 0) return 0.0;

  final prevCgpa = ref.watch(prevCgpaProvider);
  final prevCredits = ref.watch(prevCreditsProvider);

  if (prevCredits == 0) return sgpa;

  final prevQP = prevCgpa * prevCredits;
  final totalQP = prevQP + currQP;
  final totalCred = prevCredits + currCredits;
  return totalCred == 0 ? 0.0 : totalQP / totalCred;
});