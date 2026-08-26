import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/audio_player_service.dart';
import '../../data/datasources/audio_recorder_service.dart';

final audioRecorderProvider =
    Provider<AudioRecorderService>((ref) {
  final service = AudioRecorderService();

  ref.onDispose(service.dispose);

  return service;
});

final audioPlayerProvider =
    Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();

  ref.onDispose(service.dispose);

  return service;
});