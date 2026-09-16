import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../subjects/domain/entities/subject.dart';
import '../subjects/presentation/controllers/subjects_controller.dart';

Future<Subject?> showSubjectPicker(BuildContext context) {
  return showModalBottomSheet<Subject>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _SubjectPickerSheet(),
  );
}

class _SubjectPickerSheet extends ConsumerWidget {
  const _SubjectPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AsyncNotifier exposes state as AsyncValue<List<Subject>> directly —
    // no separate stream getter needed, `build()` already wires that up.
    final subjectsAsync = ref.watch(subjectsControllerProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Save to which subject?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Flexible(
              child: subjectsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Couldn\'t load subjects: $error'),
                ),
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Create a subject first, then try again.'),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: subjects.length,
                    itemBuilder: (context, i) {
                      final subject = subjects[i];
                      return ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(subject.name),
                        subtitle: subject.code != null ? Text(subject.code!) : null,
                        onTap: () => Navigator.pop(context, subject),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}