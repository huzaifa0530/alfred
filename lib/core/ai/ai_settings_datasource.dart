import 'package:alfred/core/ai/ai_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ai_providers.dart';

class AiSettingsDataSource {
  static const _storage = FlutterSecureStorage();

  static const _providerKey = 'ai_provider';
  static const _modelKey = 'ai_model';
  static const _apiKeyKeyPrefix = 'ai_api_key_'; // one key per provider

  Future<AiProvider> getProvider() async {
    final value = await _storage.read(key: _providerKey);
    return AiProvider.values.firstWhere(
      (p) => p.name == value,
      orElse: () => AiProvider.gemini,
    );
  }

  Future<void> setProvider(AiProvider provider) async {
    await _storage.write(key: _providerKey, value: provider.name);
  }

  Future<String?> getModel() => _storage.read(key: _modelKey);

  Future<void> setModel(String model) async {
    await _storage.write(key: _modelKey, value: model);
  }

  Future<String?> getApiKey(AiProvider provider) {
    return _storage.read(key: '$_apiKeyKeyPrefix${provider.name}');
  }

  Future<void> setApiKey(AiProvider provider, String apiKey) async {
    await _storage.write(key: '$_apiKeyKeyPrefix${provider.name}', value: apiKey);
  }

  Future<void> deleteApiKey(AiProvider provider) async {
    await _storage.delete(key: '$_apiKeyKeyPrefix${provider.name}');
  }
}