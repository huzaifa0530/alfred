import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqClient {
  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  final String apiKey;
  final String model;

  GroqClient({required this.apiKey, required this.model});

  Future<String> generateText(String prompt) async {
    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw StateError('Alfred took too long to respond.'),
          );

      if (response.statusCode == 429) {
        throw StateError("Alfred's free daily AI limit is used up for now — try again in a bit.");
      }
      if (response.statusCode != 200) {
        throw StateError('Alfred hit a Groq error (${response.statusCode}): ${response.body}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final text = decoded['choices']?[0]?['message']?['content'] as String?;

      if (text == null || text.trim().isEmpty) {
        throw StateError('Groq returned an empty response.');
      }
      return text.trim();
    } on http.ClientException catch (e) {
      throw StateError('Network error reaching Alfred: ${e.message}');
    }
  }
}