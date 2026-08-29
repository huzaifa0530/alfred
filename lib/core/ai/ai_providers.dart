import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_client.dart';
import 'ai_provider.dart';
import 'ai_settings_datasource.dart';

final aiSettingsDataSourceProvider = Provider<AiSettingsDataSource>((ref) {
  return AiSettingsDataSource();
});

final geminiClientProvider = Provider<AiClient>((ref) {
  return AiClient(ref.watch(aiSettingsDataSourceProvider));
});

// Exposes current selection for the Settings UI to read/react to.
final currentAiProviderProvider = FutureProvider<AiProvider>((ref) {
  return ref.watch(aiSettingsDataSourceProvider).getProvider();
});