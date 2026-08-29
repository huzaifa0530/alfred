import 'dart:convert';

import 'package:alfred/core/ai/ai_client.dart';

import '../../../../core/ai/gemini_client.dart';
import '../entities/assistant_intent.dart';

class ParseAssistantPrompt {
  final AiClient _client;

  ParseAssistantPrompt(this._client);

  Future<AssistantIntent> call({
    required String prompt,
    required List<String> subjectNames,
  }) async {
    final cleaned = prompt.trim();
    if (cleaned.isEmpty) throw ArgumentError('Prompt is empty.');

    final subjectList = subjectNames.isEmpty ? 'none' : subjectNames.join(', ');
    final today = DateTime.now().toIso8601String().split('T').first;

    final instruction =
        '''
You classify an instruction for a student app called Alfred. Today's date is $today.
The student's existing subjects are: $subjectList

Pick a "module": notes | marks | events | attendance | timetable | subjects | unknown
Pick an "operation": create | update | delete | query | unknown

Extract "fields" as a JSON object matching module+operation exactly:

notes:
  create -> {"content": "..."}
  delete -> {"contentMatch": "..."} (a snippet of the note to find and delete)
  update -> not supported, use "unknown" operation instead

attendance (create and update use the same fields; create upserts):
  create/update -> {"date": "YYYY-MM-DD" (default today), "present": true|false, "note": "..."|null}
  delete -> {"date": "YYYY-MM-DD"}

events:
  create -> {"title": "...", "description": "..."|null, "type": "assignment|exam|task|other", "priority": "low|medium|high", "dueDate": "YYYY-MM-DD"}
  update -> {"titleMatch": "...", "isCompleted": true|false|null, "title": "..."|null, "dueDate": "YYYY-MM-DD"|null, "priority": "..."|null}
  delete -> {"titleMatch": "..."}

marks (treat "I got X in Y" as update):
  create -> {"componentName": "...", "type": "quiz|assignment|midterm|final|project|performance|other", "maxMarks": 10}
  update -> {"componentNameMatch": "...", "obtainedMarks": 8.5}
  delete -> {"componentNameMatch": "..."}

subjects:
  create -> {"name": "...", "code": "..."|null, "instructor": "..."|null, "room": "..."|null}
  update -> {"name": "..."|null, "code": "..."|null, "instructor": "..."|null, "room": "..."|null}
  delete -> {} (subjectName field identifies which one)

timetable:
  create -> {"weekday": 1-7, "startTime": "HH:MM", "endTime": "HH:MM", "room": "..."|null, "teacher": "..."|null}
  update -> {"weekdayMatch": 1-7, "startTimeMatch": "HH:MM", "startTime": "..."|null, "endTime": "..."|null, "room": "..."|null}
  delete -> {"weekdayMatch": 1-7, "startTimeMatch": "HH:MM"}

Any module + "query" -> fields can be empty; fill "question" instead.

Also extract:
- subjectName: closest match from the subject list above, or null.
- question: only for operation == query — the question, rephrased simply.

Respond with ONLY raw JSON, no markdown:
{"module": "attendance", "operation": "create", "subjectName": "Physics", "fields": {"date": "$today", "present": false, "note": null}, "question": null}

INSTRUCTION:
"""
$cleaned
"""
''';
    final raw = await _client.generateText(instruction);
    final decoded = jsonDecode(_extractJson(raw)) as Map<String, dynamic>;

    final module = AssistantModule.values.firstWhere(
      (m) => m.name == decoded['module'],
      orElse: () => AssistantModule.unknown,
    );
    final operation = AssistantOperation.values.firstWhere(
      (o) => o.name == decoded['operation'],
      orElse: () => AssistantOperation.unknown,
    );

    String? clean(String? v) {
      final t = v?.trim();
      return (t == null || t.isEmpty || t.toLowerCase() == 'null') ? null : t;
    }

    return AssistantIntent(
      module: module,
      operation: operation,
      subjectName: clean(decoded['subjectName'] as String?),
      question: clean(decoded['question'] as String?),
      fields: (decoded['fields'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  String _extractJson(String raw) {
    var text = raw
        .trim()
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) {
      throw StateError('Could not parse AI response as JSON: $raw');
    }
    return text.substring(start, end + 1);
  }
}
