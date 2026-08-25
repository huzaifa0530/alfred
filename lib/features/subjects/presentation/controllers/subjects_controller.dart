import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/subject.dart';
import '../../domain/usecases/create_subject.dart';
import '../../domain/usecases/delete_subject.dart';
import '../../domain/usecases/get_subjects.dart';
import '../../domain/usecases/update_subject.dart';
import 'subjects_providers.dart';

final subjectsControllerProvider =
    AsyncNotifierProvider<SubjectsController, List<Subject>>(
  SubjectsController.new,
);

class SubjectsController extends AsyncNotifier<List<Subject>> {
  late final GetSubjects _getSubjects;
  late final CreateSubject _createSubject;
  late final UpdateSubject _updateSubject;
  late final DeleteSubject _deleteSubject;

  StreamSubscription<List<Subject>>? _subscription;

  @override
  FutureOr<List<Subject>> build() {
    _getSubjects = ref.watch(getSubjectsProvider);
    _createSubject = ref.watch(createSubjectProvider);
    _updateSubject = ref.watch(updateSubjectProvider);
    _deleteSubject = ref.watch(deleteSubjectProvider);

    ref.onDispose(() {
      _subscription?.cancel();
    });

    _listenToSubjects();

    return const [];
  }

  void _listenToSubjects() {
    _subscription?.cancel();

    _subscription = _getSubjects().listen(
      (subjects) {
        state = AsyncData(subjects);
      },
      onError: (error, stackTrace) {
        state = AsyncError(error, stackTrace);
      },
    );
  }

  Future<void> createSubject({
    required String name,
    String? code,
    String? instructor,
    String? room,
    String? color,
  }) async {
    final now = DateTime.now();

    final subject = Subject(
      id: 0,
      name: name.trim(),
      code: _clean(code),
      instructor: _clean(instructor),
      room: _clean(room),
      color: _clean(color),
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _createSubject(subject);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateSubject(Subject subject) async {
    final updatedSubject = subject.copyWith(
      updatedAt: DateTime.now(),
    );

    try {
      await _updateSubject(updatedSubject);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteSubject(int id) async {
    try {
      await _deleteSubject(id);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  String? _clean(String? value) {
    final cleaned = value?.trim();

    if (cleaned == null || cleaned.isEmpty) {
      return null;
    }

    return cleaned;
  }
}