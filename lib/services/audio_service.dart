import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final FlutterSoundRecorder _recorder =
      FlutterSoundRecorder();
  bool _isInitialized = false;

  Future<void> init() async {
    if (!_isInitialized) {
      await _recorder.openRecorder();
      _isInitialized = true;
    }
  }

  Future<bool> _requestPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<String?> startRecording() async {
    await init();

    bool hasPermission = await _requestPermission();
    if (!hasPermission) {
      print("Microphone permission denied");
      return null;
    }

    final directory =
        await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/lecture_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacMP4,
      sampleRate: 16000,
      bitRate: 64000,
    );

    return path;
  }

  Future<String?> stopRecording() async {
    return await _recorder.stopRecorder();
  }

  bool get isRecording => _recorder.isRecording;
}
