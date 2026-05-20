import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:device_info_plus/device_info_plus.dart';
import 'permission_service.dart';
import 'codec_detector.dart';

/// Provides diagnostic capabilities for the audio system.
class AudioDiagnostics {
  final CodecDetector _codecDetector;

  AudioDiagnostics(this._codecDetector);

  Future<Map<String, dynamic>> diagnoseAudioSystem(
    FlutterSoundRecorder? recorder,
    String currentState,
  ) async {
    final Map<String, dynamic> diagnosis = {};

    try {
      diagnosis['recorderInitialized'] = recorder != null;
      diagnosis['currentState'] = currentState;

      final micPermission =
          await PermissionService.requestMicrophonePermission();
      diagnosis['microphonePermission'] = micPermission.result.toString();
      diagnosis['microphoneMessage'] = micPermission.message;

      if (recorder != null) {
        try {
          diagnosis['recorderState'] = currentState;
          diagnosis['recorderObject'] = 'initialized';
        } catch (e) {
          diagnosis['recorderState'] = 'error';
          diagnosis['recorderError'] = e.toString();
        }
      }

      diagnosis['timestamp'] = DateTime.now().toIso8601String();

      developer.log(
        'Audio system diagnosis: $diagnosis',
        name: 'AudioDiagnostics',
      );

      return diagnosis;
    } catch (e) {
      diagnosis['diagnosisError'] = e.toString();
      return diagnosis;
    }
  }

  Future<bool> testMicrophone(FlutterSoundRecorder recorder) async {
    try {
      if (await isEmulator()) {
        developer.log('Microphone test skipped: running on emulator',
            name: 'AudioDiagnostics');
        return false;
      }

      final hasPermission = await _requestPermissions();
      if (!hasPermission) return false;

      final codecsToTest = [
        {'name': 'Default', 'codec': null, 'extension': 'wav'},
        {'name': 'PCM16WAV', 'codec': Codec.pcm16WAV, 'extension': 'wav'},
        {'name': 'AACADTS', 'codec': Codec.aacADTS, 'extension': 'aac'},
        {'name': 'MP3', 'codec': Codec.mp3, 'extension': 'mp3'},
      ];

      for (final codecInfo in codecsToTest) {
        try {
          final tempDir = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final testPath = path.join(
            tempDir.path,
            'test_mic_$timestamp.${codecInfo['extension']}',
          );

          if (codecInfo['codec'] == null) {
            await recorder.startRecorder(
                toFile: testPath, sampleRate: 16000, numChannels: 1);
          } else {
            await recorder.startRecorder(
              toFile: testPath,
              codec: codecInfo['codec'] as Codec,
              sampleRate: 16000,
              numChannels: 1,
            );
          }

          await Future.delayed(const Duration(seconds: 1));
          await recorder.stopRecorder();

          final file = File(testPath);
          if (await file.exists()) {
            final stats = await file.stat();
            await file.delete();

            int minSize = codecInfo['name'] == 'PCM16WAV' ? 16000 : 500;
            if (stats.size > minSize) return true;
          }

          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          developer.log(
            'Microphone test with ${codecInfo['name']} failed: $e',
            name: 'AudioDiagnostics',
          );
          try {
            await recorder.stopRecorder();
          } catch (_) {}
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      return false;
    } catch (e) {
      developer.log('Microphone test failed: $e', name: 'AudioDiagnostics');
      return false;
    }
  }

  Future<bool> testRecordingConfigurations(
      FlutterSoundRecorder recorder) async {
    final configurations = [
      {
        'name': 'Standard PCM16 16kHz',
        'codec': Codec.pcm16WAV,
        'sampleRate': 16000,
        'numChannels': 1,
      },
      {
        'name': 'PCM16 44.1kHz',
        'codec': Codec.pcm16WAV,
        'sampleRate': 44100,
        'numChannels': 1,
      },
      {
        'name': 'AAC 16kHz',
        'codec': Codec.aacADTS,
        'sampleRate': 16000,
        'numChannels': 1,
      },
      {
        'name': 'PCM16 8kHz',
        'codec': Codec.pcm16WAV,
        'sampleRate': 8000,
        'numChannels': 1,
      },
    ];

    for (final config in configurations) {
      try {
        final tempDir = await getTemporaryDirectory();
        final testPath = path.join(
          tempDir.path,
          'test_config_${DateTime.now().millisecondsSinceEpoch}.wav',
        );

        await recorder.startRecorder(
          toFile: testPath,
          codec: config['codec'] as Codec,
          sampleRate: config['sampleRate'] as int,
          numChannels: config['numChannels'] as int,
        );

        await Future.delayed(const Duration(seconds: 2));
        await recorder.stopRecorder();

        final file = File(testPath);
        if (await file.exists()) {
          final stats = await file.stat();
          await file.delete();
          if (stats.size > 2000) return true;
        }

        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        developer.log('Configuration ${config['name']} failed: $e',
            name: 'AudioDiagnostics');
        try {
          await recorder.stopRecorder();
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return false;
  }

  Future<bool> testSimpleRecording(FlutterSoundRecorder recorder) async {
    try {
      final bestCodec = await _codecDetector.findBestCodec(recorder);
      if (bestCodec == null) return false;

      final tempDir = await getTemporaryDirectory();
      final testPath = path.join(
        tempDir.path,
        'test_recording.${bestCodec['extension']}',
      );

      if (bestCodec['codec'] == null) {
        await recorder.startRecorder(
            toFile: testPath, sampleRate: 16000, numChannels: 1);
      } else {
        await recorder.startRecorder(
          toFile: testPath,
          codec: bestCodec['codec'] as Codec,
          sampleRate: 16000,
          numChannels: 1,
        );
      }

      await Future.delayed(const Duration(seconds: 2));
      await recorder.stopRecorder();

      final file = File(testPath);
      if (await file.exists()) {
        final stats = await file.stat();
        await file.delete();
        return stats.size > _codecDetector.getMinFileSize(bestCodec['name']);
      }

      return false;
    } catch (e) {
      developer.log('Test recording failed: $e', name: 'AudioDiagnostics');
      return false;
    }
  }

  Future<bool> isRunningOnEmulator() async {
    try {
      if (Platform.isAndroid) return false;
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isEmulator() async {
    try {
      if (!Platform.isAndroid) return false;
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final fingerprint = androidInfo.fingerprint.toLowerCase();
      final model = androidInfo.model.toLowerCase();
      final product = androidInfo.product.toLowerCase();
      if (fingerprint.contains('generic') ||
          fingerprint.contains('dummy') ||
          model.contains('sdk') ||
          product.contains('sdk')) {
        return true;
      }
    } catch (e) {
      developer.log('Error detecting emulator: $e', name: 'AudioDiagnostics');
    }
    return false;
  }

  Future<bool> _requestPermissions() async {
    try {
      final permissions = await PermissionService.requestAllPermissions();
      final micPermission = permissions['microphone'];
      return micPermission?.result == PermissionResult.granted;
    } catch (e) {
      return false;
    }
  }
}
