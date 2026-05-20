import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'permission_service.dart';
import 'codec_detector.dart';
import 'playback_service.dart';
import 'audio_diagnostics.dart';

enum RecorderState { idle, recording, paused, stopped, playing }

class AudioRecorderService {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  RecorderState _state = RecorderState.idle;
  String? _currentRecordingPath;

  late final CodecDetector _codecDetector;
  late final PlaybackService _playbackService;
  late final AudioDiagnostics _audioDiagnostics;

  RecorderState get state => _state;
  String? get currentRecordingPath => _currentRecordingPath;

  AudioRecorderService() {
    _codecDetector = CodecDetector();
    _playbackService = PlaybackService();
    _audioDiagnostics = AudioDiagnostics(_codecDetector);
  }

  Future<void> initialize() async {
    try {
      developer.log(
        'Initializing AudioRecorderService...',
        name: 'AudioRecorderService',
      );

      _recorder = FlutterSoundRecorder();
      _player = FlutterSoundPlayer();

      await _recorder!.openRecorder();
      await _player!.openPlayer();

      _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));
      _player!.setSubscriptionDuration(const Duration(milliseconds: 100));

      developer.log(
        'AudioRecorderService initialized successfully',
        name: 'AudioRecorderService',
      );

      await _requestPermissions();
    } catch (e) {
      developer.log(
        'Error initializing AudioRecorderService: $e',
        name: 'AudioRecorderService',
      );
      rethrow;
    }
  }

  Future<void> dispose() async {
    try {
      await _recorder?.closeRecorder();
      await _player?.closePlayer();
      _recorder = null;
      _player = null;
      developer.log(
        'AudioRecorderService disposed',
        name: 'AudioRecorderService',
      );
    } catch (e) {
      developer.log(
        'Error disposing AudioRecorderService: $e',
        name: 'AudioRecorderService',
      );
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      developer.log('Requesting permissions...', name: 'AudioRecorderService');
      final permissions = await PermissionService.requestAllPermissions();
      final micPermission = permissions['microphone'];
      final hasPermissions = micPermission?.result == PermissionResult.granted;
      developer.log(
        'Permissions result: $hasPermissions (mic: ${micPermission?.result})',
        name: 'AudioRecorderService',
      );
      return hasPermissions;
    } catch (e) {
      developer.log(
        'Error requesting permissions: $e',
        name: 'AudioRecorderService',
      );
      return false;
    }
  }

  Future<bool> startRecording() async {
    developer.log('startRecording called', name: 'AudioRecorderService');

    if (_recorder == null) {
      developer.log('ERROR: Recorder is null', name: 'AudioRecorderService');
      return false;
    }

    if (_state != RecorderState.idle) {
      developer.log(
        'Recorder not in idle state, current state: $_state. Attempting to reset...',
        name: 'AudioRecorderService',
      );
      if (_state == RecorderState.playing) {
        await stopPlaying();
      }
      reset();
      if (_state != RecorderState.idle) return false;
    }

    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        throw Exception('Microphone permission denied');
      }

      // Ensure recorder is ready
      try {
        if (_recorder!.isRecording) {
          await _recorder!.stopRecorder();
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (e) {
        await _recorder!.closeRecorder();
        await Future.delayed(const Duration(milliseconds: 100));
        await _recorder!.openRecorder();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      await Future.delayed(const Duration(milliseconds: 200));

      final bestCodec = await _codecDetector.findBestCodec(_recorder!);
      if (bestCodec == null) {
        _state = RecorderState.idle;
        return false;
      }

      developer.log(
        'Using codec: ${bestCodec['name']}',
        name: 'AudioRecorderService',
      );

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = path.join(
        directory.path,
        'recording_$timestamp.${bestCodec['extension']}',
      );

      if (bestCodec['codec'] == null) {
        await _recorder!.startRecorder(
          toFile: _currentRecordingPath,
          sampleRate: 16000,
          numChannels: 1,
        );
      } else {
        await _recorder!.startRecorder(
          toFile: _currentRecordingPath,
          codec: bestCodec['codec'] as Codec,
          sampleRate: 16000,
          numChannels: 1,
        );
      }

      _state = RecorderState.recording;

      await Future.delayed(const Duration(milliseconds: 500));

      if (_state == RecorderState.recording && _recorder!.isRecording) {
        developer.log(
          'Recording is active and running',
          name: 'AudioRecorderService',
        );
      } else if (!_recorder!.isRecording) {
        _state = RecorderState.idle;
        return false;
      }

      return true;
    } catch (e) {
      developer.log(
        'ERROR starting recording: $e',
        name: 'AudioRecorderService',
      );
      _state = RecorderState.idle;
      return false;
    }
  }

  Future<String?> stopRecording() async {
    if (_recorder == null || _state != RecorderState.recording) {
      return null;
    }

    try {
      await _recorder!.stopRecorder();
      _state = RecorderState.stopped;

      if (_currentRecordingPath != null &&
          await File(_currentRecordingPath!).exists()) {
        final file = File(_currentRecordingPath!);
        final stats = await file.stat();

        final codecName = _codecDetector.bestCodec?['name'];
        final minSizeBytes = _codecDetector.getMinFileSize(codecName);

        if (stats.size > minSizeBytes) {
          developer.log(
            'Recording stopped, file: $_currentRecordingPath (${stats.size} bytes)',
            name: 'AudioRecorderService',
          );
          return _currentRecordingPath;
        } else {
          developer.log(
            'Recording file too small (${stats.size} bytes < $minSizeBytes)',
            name: 'AudioRecorderService',
          );
          return null;
        }
      }

      _state = RecorderState.idle;
      return null;
    } catch (e) {
      developer.log(
        'Error stopping recording: $e',
        name: 'AudioRecorderService',
      );
      _state = RecorderState.idle;
      return null;
    }
  }

  Future<void> pauseRecording() async {
    if (_recorder == null || _state != RecorderState.recording) {
      return;
    }

    try {
      await _recorder!.pauseRecorder();
      _state = RecorderState.paused;
    } catch (e) {
      developer.log(
        'Error pausing recording: $e',
        name: 'AudioRecorderService',
      );
    }
  }

  Future<void> resumeRecording() async {
    if (_recorder == null || _state != RecorderState.paused) {
      return;
    }

    try {
      await _recorder!.resumeRecorder();
      _state = RecorderState.recording;
    } catch (e) {
      developer.log(
        'Error resuming recording: $e',
        name: 'AudioRecorderService',
      );
    }
  }

  Future<bool> playRecording(String filePath) async {
    if (_player == null || !await File(filePath).exists()) {
      return false;
    }

    try {
      _state = RecorderState.playing;
      final result = await _playbackService.play(_player!, filePath, () {
        _state = RecorderState.idle;
      });
      if (!result) _state = RecorderState.idle;
      return result;
    } catch (e) {
      developer.log(
        'Error playing recording: $e',
        name: 'AudioRecorderService',
      );
      _state = RecorderState.idle;
      return false;
    }
  }

  Future<void> stopPlaying() async {
    if (_player == null) return;

    try {
      await _playbackService.stop(_player!);
      _state = RecorderState.idle;
    } catch (e) {
      developer.log(
        'Error stopping playback: $e',
        name: 'AudioRecorderService',
      );
    }
  }

  Future<double?> getRecordingDuration(String filePath) async {
    return _playbackService.getRecordingDuration(filePath);
  }

  Future<void> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      developer.log(
        'Error deleting recording: $e',
        name: 'AudioRecorderService',
      );
    }
  }

  // Get recording level (for UI visualization)
  Stream<RecordingDisposition>? getRecorderStream() {
    return _recorder?.onProgress;
  }

  void reset() {
    _state = RecorderState.idle;
    _currentRecordingPath = null;
  }

  void resetCodecCache() {
    _codecDetector.resetCache();
  }

  Future<void> forceStop() async {
    try {
      if (_recorder != null) {
        try {
          await _recorder!.stopRecorder();
        } catch (e) {
          developer.log(
            'Error force stopping recorder: $e',
            name: 'AudioRecorderService',
          );
        }
      }

      if (_player != null) {
        try {
          await _player!.stopPlayer();
        } catch (e) {
          developer.log(
            'Error force stopping player: $e',
            name: 'AudioRecorderService',
          );
        }
      }

      reset();
    } catch (e) {
      developer.log('Error in forceStop: $e', name: 'AudioRecorderService');
      reset();
    }
  }

  // --- Delegate methods for backward compatibility ---

  Future<Map<String, dynamic>> diagnoseAudioSystem() async {
    return _audioDiagnostics.diagnoseAudioSystem(_recorder, _state.toString());
  }

  Future<bool> testMicrophone() async {
    if (_recorder == null) return false;
    return _audioDiagnostics.testMicrophone(_recorder!);
  }

  Future<bool> testRecordingConfigurations() async {
    if (_recorder == null) return false;
    return _audioDiagnostics.testRecordingConfigurations(_recorder!);
  }

  Future<Map<String, bool>> testSupportedCodecs() async {
    if (_recorder == null) return {};
    return _codecDetector.testSupportedCodecs(_recorder!);
  }

  Future<bool> isRunningOnEmulator() async {
    return _audioDiagnostics.isRunningOnEmulator();
  }

  Future<bool> isEmulator() async {
    return _audioDiagnostics.isEmulator();
  }

  Future<bool> testSimpleRecording() async {
    if (_recorder == null) return false;
    return _audioDiagnostics.testSimpleRecording(_recorder!);
  }

  Future<Map<String, dynamic>?> findBestCodec() async {
    if (_recorder == null) return null;
    return _codecDetector.findBestCodec(_recorder!);
  }
}
