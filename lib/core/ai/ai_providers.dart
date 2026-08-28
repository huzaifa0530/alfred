import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gemini_client.dart';

final geminiClientProvider = Provider<GeminiClient>((ref) {
  return GeminiClient();
});
