import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/daos/marks_dao.dart';
import '../../../../core/database/database_providers.dart';

import '../../data/datasources/marks_local_datasource.dart';
import '../../data/repositories/marks_repository_impl.dart';

import '../../domain/entities/mark.dart';
import '../../domain/entities/mark_component.dart';
import '../../domain/repositories/marks_repository.dart';

import '../../domain/usecases/create_mark_component.dart';
import '../../domain/usecases/update_mark_component.dart';
import '../../domain/usecases/delete_mark_component.dart';
import '../../domain/usecases/save_mark.dart';
import '../../domain/usecases/get_marks.dart';
import '../../domain/usecases/get_subject_marks.dart';


// ============================================================
// DAO
// ============================================================

final marksDaoProvider = Provider<MarksDao>((ref) {
  return MarksDao(ref.watch(appDatabaseProvider));
});


// ============================================================
// LOCAL DATASOURCE
// ============================================================

final marksLocalDataSourceProvider =
    Provider<MarksLocalDataSource>((ref) {
  return MarksLocalDataSource(
    ref.watch(marksDaoProvider),
  );
});


// ============================================================
// REPOSITORY
// ============================================================

final marksRepositoryProvider = Provider<MarksRepository>((ref) {
  return MarksRepositoryImpl(
    ref.watch(marksLocalDataSourceProvider),
  );
});


// ============================================================
// USE CASES
// ============================================================

final createMarkComponentProvider =
    Provider<CreateMarkComponent>((ref) {
  return CreateMarkComponent(
    ref.watch(marksRepositoryProvider),
  );
});

final updateMarkComponentProvider =
    Provider<UpdateMarkComponent>((ref) {
  return UpdateMarkComponent(
    ref.watch(marksRepositoryProvider),
  );
});

final deleteMarkComponentProvider =
    Provider<DeleteMarkComponent>((ref) {
  return DeleteMarkComponent(
    ref.watch(marksRepositoryProvider),
  );
});

final saveMarkProvider = Provider<SaveMark>((ref) {
  return SaveMark(
    ref.watch(marksRepositoryProvider),
  );
});

final getMarksProvider = Provider<GetMarks>((ref) {
  return GetMarks(
    ref.watch(marksRepositoryProvider),
  );
});

final getSubjectMarksProvider =
    Provider<GetSubjectMarks>((ref) {
  return GetSubjectMarks(
    ref.watch(marksRepositoryProvider),
  );
});


// ============================================================
// ALL MARKS
// ============================================================

final marksProvider =
    StreamProvider<List<Mark>>((ref) {
  return ref.watch(getMarksProvider).call();
});


// ============================================================
// MARKS FOR ONE SUBJECT
// ============================================================

final subjectMarksProvider =
    StreamProvider.family<List<Mark>, int>((ref, subjectId) {
  return ref
      .watch(getSubjectMarksProvider)
      .call(subjectId);
});


// ============================================================
// COMPONENTS FOR ONE SUBJECT
// ============================================================

final subjectMarkComponentsProvider =
    StreamProvider.family<List<MarkComponent>, int>(
  (ref, subjectId) {
    return ref
        .watch(marksRepositoryProvider)
        .watchComponentsForSubject(subjectId);
  },
);