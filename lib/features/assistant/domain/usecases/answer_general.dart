import '../../../../core/ai/alfred_persona.dart';
import '../../../../core/ai/ai_client.dart';

class AnswerGeneral {
  final AiClient _client;
  AnswerGeneral(this._client);

  Future<String> call(String question) async {
    final prompt = '''
${AlfredPersona.preamble}

Master Wayne has asked you something unrelated to his notes, marks, events,
attendance, or timetable. Simply answer as Alfred would — briefly, warmly,
with your usual dry wit where it fits.

QUESTION:
$question
''';
    return _client.generateText(prompt);
  }
}