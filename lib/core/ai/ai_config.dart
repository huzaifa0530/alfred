class AiConfig {
  AiConfig._();

  /// Get a free key at https://aistudio.google.com/apikey
  static const String apiKey = 'AQ.Ab8RN6KQHkYlI7aP7HYIPyN6jMZ7S2hCULmaOU0zQZzkQwrMvw';

  /// Free-tier model. Swap to 'gemini-2.0-flash' if this one is
  /// unavailable in your region/quota.
  static const String modelName = 'gemini-3.6-flash';
}