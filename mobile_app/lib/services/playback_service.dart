import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter_sound/flutter_sound.dart';

/// Handles audio playback functionality.
class PlaybackService {
  /// Play audio from [filePath] using the provided [player].
  /// Calls [onFinished] when playback completes.
  Future<bool> play(
    FlutterSoundPlayer player,
    String filePath,
    void Function()? onFinished,
  ) async {
    if (!await File(filePath).exists()) return false;

    try {
      await player.startPlayer(
        fromURI: filePath,
        whenFinished: onFinished,
      );
      return true;
    } catch (e) {
      developer.log('Error playing recording: $e', name: 'PlaybackService');
      return false;
    }
  }

  /// Stop playback on the provided [player].
  Future<void> stop(FlutterSoundPlayer player) async {
    try {
      await player.stopPlayer();
    } catch (e) {
      developer.log('Error stopping playback: $e', name: 'PlaybackService');
    }
  }

  /// Get the duration of a recording file. Currently returns null
  /// as duration calculation is performed by the backend.
  Future<double?> getRecordingDuration(String filePath) async {
    if (!await File(filePath).exists()) return null;
    return null;
  }
}
