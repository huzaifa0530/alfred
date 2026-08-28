import 'package:alfred/core/ai/ai_providers.dart';
import 'package:alfred/core/ai/gemini_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('geminiClientProvider exposes a GeminiClient instance', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final client = container.read(geminiClientProvider);

    expect(client, isA<GeminiClient>());
  });
}
