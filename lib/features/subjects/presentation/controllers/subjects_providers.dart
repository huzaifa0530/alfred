import 'package:alfred/features/subjects/domain/repositories/subjects_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/daos/subjects_dao.dart';
import '../../../../core/database/database_providers.dart';
import '../../data/datasources/subjects_local_datasource.dart';
import '../../data/repositories/subjects_repository_impl.dart';
import '../../domain/repositories/subjects_repository.dart';
import '../../domain/usecases/create_subject.dart';
import '../../domain/usecases/delete_subject.dart';
import '../../domain/usecases/get_subject.dart';
import '../../domain/usecases/get_subjects.dart';
import '../../domain/usecases/update_subject.dart';

final subjectsDaoProvider = Provider<SubjectsDao>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return SubjectsDao(database);
});

final subjectsLocalDataSourceProvider =
    Provider<SubjectsLocalDataSource>((ref) {
  final dao = ref.watch(subjectsDaoProvider);

  return SubjectsLocalDataSource(dao);
});

final subjectsRepositoryProvider = Provider<SubjectsRepository>((ref) {
  final dataSource = ref.watch(
    subjectsLocalDataSourceProvider,
  );

  return SubjectsRepositoryImpl(dataSource);
});

final getSubjectsProvider = Provider<GetSubjects>((ref) {
  return GetSubjects(
    ref.watch(subjectsRepositoryProvider),
  );
});

final getSubjectProvider = Provider<GetSubject>((ref) {
  return GetSubject(
    ref.watch(subjectsRepositoryProvider),
  );
});

final createSubjectProvider = Provider<CreateSubject>((ref) {
  return CreateSubject(
    ref.watch(subjectsRepositoryProvider),
  );
});

final updateSubjectProvider = Provider<UpdateSubject>((ref) {
  return UpdateSubject(
    ref.watch(subjectsRepositoryProvider),
  );
});

final deleteSubjectProvider = Provider<DeleteSubject>((ref) {
  return DeleteSubject(
    ref.watch(subjectsRepositoryProvider),
  );
});