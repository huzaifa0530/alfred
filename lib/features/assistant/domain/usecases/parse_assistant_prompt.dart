import 'dart:convert';

import 'package:alfred/core/ai/ai_client.dart';

import '../../../../core/ai/gemini_client.dart';
import '../entities/assistant_intent.dart';

class ParseAssistantPrompt {
  final AiClient _client;

  ParseAssistantPrompt(this._client);
Future<List<AssistantIntent>> call({
  required String prompt,
  required List<String> subjectNames,
}) async {
  final cleaned = prompt.trim();
  if (cleaned.isEmpty) throw ArgumentError('Prompt is empty.');

  final subjectList = subjectNames.isEmpty ? 'none' : subjectNames.join(', ');
  final today = DateTime.now();
  final todayStr = today.toIso8601String().split('T').first;
  final tomorrowStr = today.add(const Duration(days: 1)).toIso8601String().split('T').first;

  final instruction = '''

You classify one or more instructions for a student app, spoken to Alfred by
Master Wayne. Today is $todayStr, tomorrow is $tomorrowStr.
Existing subjects: $subjectList

The instruction may contain MULTIPLE separate requests (e.g. "add a note and
mark me present"). Return an "actions" array with one object per request,
in the order given. Usually this array has exactly one item.

Each action has:
- "module": notes | marks | events | attendance | timetable | subjects | general | unknown
- "operation": create | update | delete | query | unknown
- "subjectName": closest match from the list, or null
- "question": only for query — the question, rephrased simply
- "fields": JSON object matching module+operation (see below)

Use "general" + "query" for ANYTHING not about the student's actual app data —
small talk, jokes, opinions, general knowledge, "how are you", etc. Always
put the original question text in "question" for general.

notes: create -> {"content": "..."} | delete -> {"contentMatch": "..."}
attendance: create/update -> {"date": "YYYY-MM-DD", "present": true, "note": null}
  (present MUST be a real JSON boolean, never a string) | delete -> {"date": "YYYY-MM-DD"}
events: create -> {"title": "...", "description": null, "type": "task", "priority": "medium", "dueDate": "YYYY-MM-DD", "dueTime": "HH:MM"|null}
  (dueTime is 24-hour format, e.g. "23:20" for 11:20 PM. Only include dueTime
  if the student actually mentioned a specific time — otherwise use null.)
  update -> {"titleMatch": "...", "isCompleted": true, "title": null, "dueDate": null, "dueTime": null, "priority": null}
marks: create -> {"componentName": "...", "type": "quiz", "maxMarks": 10}
  update -> {"componentNameMatch": "...", "obtainedMarks": 8.5} | delete -> {"componentNameMatch": "..."}
subjects: create -> {"name": "...", "code": null, "instructor": null, "room": null}
  update -> {same fields, any null = unchanged} | delete -> {}
timetable: create -> {"weekday": 1-7, "startTime": "HH:MM", "endTime": "HH:MM", "room": null, "teacher": null}
  update -> {"weekdayMatch": 1-7, "startTimeMatch": "HH:MM", "startTime": null, "endTime": null, "room": null}
  delete -> {"weekdayMatch": 1-7, "startTimeMatch": "HH:MM"}
  query -> {"day": "today"|"tomorrow"|"YYYY-MM-DD"|null} — subjectName may be null,
  meaning "show the whole day across all subjects", which is a valid and common request.
focusAlarm: create/update -> {"intervalMinutes": 20} (start/change interval)
  delete -> {} (stop it)
Any module + query -> fields optional, fill "question".

Respond with ONLY raw JSON, no markdown:
{"actions": [{"module": "attendance", "operation": "create", "subjectName": "Physics", "fields": {"date": "$todayStr", "present": true, "note": null}, "question": null}]}

INSTRUCTION:
"""
$cleaned
"""
''';

  final raw = await _client.generateText(instruction);
  final decoded = jsonDecode(_extractJson(raw)) as Map<String, dynamic>;
  final actions = (decoded['actions'] as List?) ?? [];

  return actions.map((a) {
    final map = a as Map<String, dynamic>;
    final module = AssistantModule.values.firstWhere(
      (m) => m.name == map['module'],
      orElse: () => AssistantModule.unknown,
    );
    final operation = AssistantOperation.values.firstWhere(
      (o) => o.name == map['operation'],
      orElse: () => AssistantOperation.unknown,
    );

    String? clean(String? v) {
      final t = v?.trim();
      return (t == null || t.isEmpty || t.toLowerCase() == 'null') ? null : t;
    }

    return AssistantIntent(
      module: module,
      operation: operation,
      subjectName: clean(map['subjectName'] as String?),
      question: clean(map['question'] as String?),
      fields: (map['fields'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }).toList();
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
