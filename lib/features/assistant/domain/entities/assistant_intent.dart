enum AssistantModule { notes, marks, events, attendance, timetable, subjects, general, unknown }
enum AssistantOperation { create, update, delete, query, unknown }

class AssistantIntent {
  final AssistantModule module;
  final AssistantOperation operation;
  final String? subjectName;
  final String? question;       // for operation == query
  final Map<String, dynamic> fields; // operation-specific payload, e.g. {"present": true, "date": "2026-08-29"}

  const AssistantIntent({
    required this.module,
    required this.operation,
    this.subjectName,
    this.question,
    this.fields = const {},
  });
}