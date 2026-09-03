// core/firebase/firebase_credentials_parser.dart
import 'dart:convert';
import 'firebase_credentials.dart';

class FirebaseCredentialsParseException implements Exception {
  final String message;
  FirebaseCredentialsParseException(this.message);
  @override
  String toString() => message;
}

class FirebaseCredentialsParser {
  /// Accepts either raw JSON, or the `const firebaseConfig = {...};` JS
  /// snippet users commonly copy straight from the Firebase console —
  /// strips the wrapper and trailing semicolon before parsing.
  FirebaseCredentials parse(String rawInput) {
    var text = rawInput.trim();

    final braceStart = text.indexOf('{');
    final braceEnd = text.lastIndexOf('}');
    if (braceStart == -1 || braceEnd == -1 || braceEnd < braceStart) {
      throw FirebaseCredentialsParseException(
        'Could not find a config object in the pasted text.',
      );
    }
    text = text.substring(braceStart, braceEnd + 1);

    // JS object keys aren't quoted JSON — quote bare keys before decoding.
    text = text.replaceAllMapped(
      RegExp(r'([{,]\s*)([A-Za-z0-9_]+)(\s*:)'),
      (m) => '${m[1]}"${m[2]}"${m[3]}',
    );

    late Map<String, dynamic> json;
    try {
      json = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      throw FirebaseCredentialsParseException(
        'That doesn\'t look like a valid Firebase config.',
      );
    }

    for (final key in ['apiKey', 'appId', 'messagingSenderId', 'projectId', 'storageBucket']) {
      if (json[key] == null || (json[key] as String).isEmpty) {
        throw FirebaseCredentialsParseException('Missing "$key" in the pasted config.');
      }
    }

    return FirebaseCredentials.fromJson(json);
  }
}