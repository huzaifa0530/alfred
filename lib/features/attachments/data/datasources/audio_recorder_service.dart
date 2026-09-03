
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder;

  AudioRecorderService({
    AudioRecorder? recorder,
  }) : _recorder = recorder ?? AudioRecorder();

  Future<bool> hasPermission() {
    return _recorder.hasPermission();
  }

  Future<void> start() async {
    final allowed = await _recorder.hasPermission();

    if (!allowed) {
      throw Exception(
        'Microphone permission denied.',
      );
    }

    final directory =
        await getTemporaryDirectory();

    final path =
        '${directory.path}/alfred_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );
  }

  Future<String?> stop() {
    return _recorder.stop();
  }

  Future<void> cancel() async {
    await _recorder.cancel();
  }

  Future<bool> isRecording() {
    return _recorder.isRecording();
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}