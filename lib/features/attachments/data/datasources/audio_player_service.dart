import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _player;

  AudioPlayerService({
    AudioPlayer? player,
  }) : _player = player ?? AudioPlayer();

  Stream<PlayerState> get playerStateStream =>
      _player.onPlayerStateChanged;

  Stream<Duration> get positionStream =>
      _player.onPositionChanged;

  Stream<Duration> get durationStream =>
      _player.onDurationChanged;

  Future<void> play(String path) async {
    await _player.play(
      DeviceFileSource(path),
    );
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}