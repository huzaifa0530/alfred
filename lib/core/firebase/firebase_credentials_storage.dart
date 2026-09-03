// core/firebase/firebase_credentials_storage.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'firebase_credentials.dart';

class FirebaseCredentialsStorage {
  static const _key = 'user_firebase_credentials';
  final _storage = const FlutterSecureStorage();

  Future<void> save(FirebaseCredentials creds) {
    return _storage.write(key: _key, value: jsonEncode(creds.toJson()));
  }

  Future<FirebaseCredentials?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    return FirebaseCredentials.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clear() => _storage.delete(key: _key);
}