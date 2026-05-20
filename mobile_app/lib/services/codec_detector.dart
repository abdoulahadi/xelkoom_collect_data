import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Detects and caches the best available audio codec for the device.
class CodecDetector {
  Map<String, dynamic>? _bestCodec;

  Map<String, dynamic>? get bestCodec => _bestCodec;

  void resetCache() {
    developer.log('Resetting codec cache', name: 'CodecDetector');
    _bestCodec = null;
  }

  Future<Map<String, dynamic>?> findBestCodec(
      FlutterSoundRecorder recorder) async {
    if (_bestCodec != null) {
      developer.log(
        'Using cached best codec: ${_bestCodec!['name']}',
        name: 'CodecDetector',
      );
      return _bestCodec;
    }

    developer.log('Finding best available codec...', name: 'CodecDetector');

    final codecsToTest = [
      {'name': 'Default', 'codec': null, 'extension': 'wav'},
      {'name': 'AACADTS', 'codec': Codec.aacADTS, 'extension': 'aac'},
      {'name': 'PCM16WAV', 'codec': Codec.pcm16WAV, 'extension': 'wav'},
      {'name': 'MP3', 'codec': Codec.mp3, 'extension': 'mp3'},
    ];

    for (final codecInfo in codecsToTest) {
      try {
        developer.log(
          'Testing codec: ${codecInfo['name']}',
          name: 'CodecDetector',
        );

        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final testPath = path.join(
          tempDir.path,
          'test_codec_$timestamp.${codecInfo['extension']}',
        );

        if (codecInfo['codec'] == null) {
          await recorder.startRecorder(
            toFile: testPath,
            sampleRate: 16000,
            numChannels: 1,
          );
        } else {
          await recorder.startRecorder(
            toFile: testPath,
            codec: codecInfo['codec'] as Codec,
            sampleRate: 16000,
            numChannels: 1,
          );
        }

        await Future.delayed(const Duration(milliseconds: 500));
        await recorder.stopRecorder();

        final file = File(testPath);
        if (await file.exists()) {
          final stats = await file.stat();
          await file.delete();

          if (stats.size > 100) {
            developer.log(
              'Found working codec: ${codecInfo['name']} (${stats.size} bytes)',
              name: 'CodecDetector',
            );
            _bestCodec = Map<String, dynamic>.from(codecInfo);
            return _bestCodec;
          }
        }

        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        developer.log(
          'Codec ${codecInfo['name']} failed: $e',
          name: 'CodecDetector',
        );
        try {
          await recorder.stopRecorder();
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    developer.log('No working codec found', name: 'CodecDetector');
    return null;
  }

  Future<Map<String, bool>> testSupportedCodecs(
      FlutterSoundRecorder recorder) async {
    final supportedCodecs = <String, bool>{};

    final codecsToTest = [
      {'name': 'Default', 'codec': null},
      {'name': 'PCM16WAV', 'codec': Codec.pcm16WAV},
      {'name': 'AACADTS', 'codec': Codec.aacADTS},
      {'name': 'MP3', 'codec': Codec.mp3},
    ];

    for (final codecInfo in codecsToTest) {
      try {
        final tempDir = await getTemporaryDirectory();
        final testPath = path.join(
          tempDir.path,
          'test_${codecInfo['name']}.tmp',
        );

        if (codecInfo['codec'] == null) {
          await recorder.startRecorder(toFile: testPath);
        } else {
          await recorder.startRecorder(
            toFile: testPath,
            codec: codecInfo['codec'] as Codec,
          );
        }

        await Future.delayed(const Duration(milliseconds: 500));
        await recorder.stopRecorder();

        final file = File(testPath);
        final exists = await file.exists();
        if (exists) await file.delete();

        supportedCodecs[codecInfo['name'] as String] = exists;
        developer.log(
          'Codec ${codecInfo['name']}: ${exists ? "SUPPORTED" : "NOT SUPPORTED"}',
          name: 'CodecDetector',
        );
      } catch (e) {
        supportedCodecs[codecInfo['name'] as String] = false;
        developer.log(
          'Codec ${codecInfo['name']}: ERROR - $e',
          name: 'CodecDetector',
        );
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    return supportedCodecs;
  }

  /// Minimum valid file size for a given codec name.
  int getMinFileSize(String? codecName) {
    switch (codecName) {
      case 'PCM16WAV':
        return 5000;
      case 'AACADTS':
      case 'MP3':
        return 1000;
      case 'Default':
        return 2000;
      default:
        return 2000;
    }
  }
}
