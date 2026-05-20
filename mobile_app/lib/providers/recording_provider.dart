import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_recorder_service.dart';
import '../services/api_service.dart';
import '../services/permission_service.dart';
import '../models/recording.dart';
import '../models/sentence.dart';
import 'auth_provider.dart';

// Provider pour le service d'enregistrement audio
final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  return AudioRecorderService();
});

// Provider pour l'Ã©tat de l'enregistrement
final recordingStateProvider =
    StateNotifierProvider<RecordingStateNotifier, RecordingState>((ref) {
      final audioService = ref.read(audioRecorderServiceProvider);
      final apiService = ref.read(apiServiceProvider);
      return RecordingStateNotifier(audioService, apiService);
    });

// Ã‰tats possibles de l'enregistrement
enum RecordingProcessState {
  idle,
  preparing, // Nouveau : en prÃ©paration de l'enregistrement
  recording,
  stopped,
  playing,
  uploading,
  uploaded,
  error,
}

// Ã‰tat de l'enregistrement
class RecordingState {
  final RecordingProcessState status;
  final String? filePath;
  final String? errorMessage;
  final double? duration;
  final bool isPlaying;

  const RecordingState({
    this.status = RecordingProcessState.idle,
    this.filePath,
    this.errorMessage,
    this.duration,
    this.isPlaying = false,
  });

  RecordingState copyWith({
    RecordingProcessState? status,
    String? filePath,
    String? errorMessage,
    double? duration,
    bool? isPlaying,
  }) {
    return RecordingState(
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      errorMessage: errorMessage ?? this.errorMessage,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

// NotifierState pour gÃ©rer l'enregistrement
class RecordingStateNotifier extends StateNotifier<RecordingState> {
  final AudioRecorderService _audioService;
  final ApiService _apiService;

  // Variables pour mesurer le temps d'enregistrement
  DateTime? _recordingStartTime;

  RecordingStateNotifier(this._audioService, this._apiService)
    : super(const RecordingState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      print('Initializing recording provider...');
      await _audioService.initialize();
      print('Recording provider initialized successfully');
    } catch (e) {
      print('ERROR initializing recording provider: $e');
      state = state.copyWith(
        status: RecordingProcessState.error,
        errorMessage: 'Failed to initialize audio service: $e',
      );
    }
  }

  Future<void> startRecording() async {
    // Si l'Ã©tat n'est pas idle, essayer de forcer la rÃ©initialisation
    if (state.status != RecordingProcessState.idle) {
      print('Current status is ${state.status}, attempting force reset...');
      await forceReset();

      // VÃ©rifier si la rÃ©initialisation a fonctionnÃ©
      if (state.status != RecordingProcessState.idle) {
        print('Failed to reset to idle state, current status: ${state.status}');
        return;
      }
    }

    try {
      print('Preparing recording...');
      state = state.copyWith(status: RecordingProcessState.preparing);

      // VÃ©rifier les permissions avant de commencer l'enregistrement
      final micPermission =
          await PermissionService.requestMicrophonePermission();

      if (micPermission.result != PermissionResult.granted) {
        print(
          'ERROR: Microphone permission not granted: ${micPermission.message}',
        );
        state = state.copyWith(
          status: RecordingProcessState.error,
          errorMessage: micPermission.message,
        );
        return;
      }

      print('Starting recording directly...');
      final success = await _audioService.startRecording();
      if (!success) {
        print('ERROR: Failed to start recording, running diagnostics...');

        // ExÃ©cuter un diagnostic pour comprendre le problÃ¨me
        final diagnosis = await _audioService.diagnoseAudioSystem();
        print('Audio system diagnosis: $diagnosis');

        String errorMessage = 'Failed to start recording.';
        if (diagnosis.containsKey('microphonePermission')) {
          errorMessage += ' Microphone: ${diagnosis['microphonePermission']}';
        }
        if (diagnosis.containsKey('recorderError')) {
          errorMessage += ' Recorder error: ${diagnosis['recorderError']}';
        }

        state = state.copyWith(
          status: RecordingProcessState.error,
          errorMessage: errorMessage,
        );
      } else {
        print('Recording started successfully');
        _recordingStartTime =
            DateTime.now(); // Enregistrer l'heure de dÃ©but MAINTENANT
        state = state.copyWith(status: RecordingProcessState.recording);
      }
    } catch (e) {
      print('ERROR in startRecording: $e');
      _recordingStartTime = null; // RÃ©initialiser en cas d'erreur
      state = state.copyWith(
        status: RecordingProcessState.error,
        errorMessage: 'Recording error: $e',
      );
    }
  }

  Future<void> stopRecording() async {
    if (state.status != RecordingProcessState.recording) return;

    try {
      print('Stopping recording...');
      final filePath = await _audioService.stopRecording();

      if (filePath != null) {
        // Calculer la durÃ©e rÃ©elle d'enregistrement
        double? duration;
        if (_recordingStartTime != null) {
          final recordingEndTime = DateTime.now();
          final actualDuration = recordingEndTime.difference(
            _recordingStartTime!,
          );
          duration =
              actualDuration.inMilliseconds / 1000.0; // Convertir en secondes
          print('Actual recording duration: ${duration}s');
        } else {
          // Fallback sur l'ancienne mÃ©thode si pas de temps de dÃ©but
          final file = File(filePath);
          final stats = await file.stat();
          duration = _calculateDuration(stats.size);
          print('Estimated duration from file size: ${duration}s');
        }

        // Valider que la durÃ©e est raisonnable (au moins 0.1 seconde)
        if (duration < 0.1) {
          print('WARNING: Recording duration too short: ${duration}s');
          duration = 0.1; // Minimum pour Ã©viter les erreurs
        }

        print(
          'Recording stopped successfully. File: $filePath, Duration: ${duration}s',
        );

        state = state.copyWith(
          status: RecordingProcessState.stopped,
          filePath: filePath,
          duration: duration,
        );
      } else {
        print('ERROR: Failed to save recording - file too small or corrupted');

        // ExÃ©cuter un diagnostic pour comprendre le problÃ¨me
        final diagnosis = await _audioService.diagnoseAudioSystem();
        print('Audio system diagnosis after failed recording: $diagnosis');

        state = state.copyWith(
          status: RecordingProcessState.error,
          errorMessage:
              'Recording failed - no audio captured. Please speak closer to the microphone and try again.',
        );
      }
    } catch (e) {
      print('ERROR in stopRecording: $e');
      state = state.copyWith(
        status: RecordingProcessState.error,
        errorMessage: 'Stop recording error: $e',
      );
    }
  }

  Future<void> playRecording() async {
    if (state.filePath == null || state.status != RecordingProcessState.stopped)
      return;

    try {
      print('Playing recording...');
      state = state.copyWith(isPlaying: true);
      await _audioService.playRecording(state.filePath!);
      await Future.delayed(Duration(seconds: (state.duration ?? 1).round()));
      state = state.copyWith(isPlaying: false);
      print('Playback finished');
    } catch (e) {
      print('ERROR in playRecording: $e');
      state = state.copyWith(
        isPlaying: false,
        status: RecordingProcessState.error,
        errorMessage: 'Playback error: $e',
      );
    }
  }

  Future<void> stopPlayback() async {
    try {
      await _audioService.stopPlaying();
      state = state.copyWith(isPlaying: false);
      print('Playback stopped');
    } catch (e) {
      print('ERROR in stopPlayback: $e');
      state = state.copyWith(
        isPlaying: false,
        errorMessage: 'Stop playback error: $e',
      );
    }
  }

  Future<Recording?> uploadRecording(Sentence sentence) async {
    if (state.filePath == null || state.status != RecordingProcessState.stopped) {
      return null;
    }

    try {
      print('Uploading recording...');
      state = state.copyWith(status: RecordingProcessState.uploading);

      final recording = await _apiService.uploadRecording(
        sentenceId: sentence.id,
        audioFilePath: state.filePath!,
      );

      print('Recording uploaded successfully');
      state = state.copyWith(status: RecordingProcessState.uploaded);
      return recording;
    } catch (e) {
      print('ERROR in uploadRecording: $e');
      state = state.copyWith(
        status: RecordingProcessState.error,
        errorMessage: 'Upload error: $e',
      );
      return null;
    }
  }

  void reset() {
    print('Resetting recording state');
    _recordingStartTime = null; // RÃ©initialiser le temps d'enregistrement
    state = const RecordingState();
  }

  void clearError() {
    print('Clearing error state');
    _recordingStartTime =
        null; // RÃ©initialiser aussi lors du nettoyage d'erreur
    state = state.copyWith(status: RecordingProcessState.idle, errorMessage: null);
  }

  Future<void> forceReset() async {
    print('Force resetting recording provider...');
    try {
      await _audioService.forceStop();
      state = const RecordingState(); // Reset to initial state
      print('Recording provider force reset completed');
    } catch (e) {
      print('ERROR in force reset: $e');
      state = state.copyWith(
        status: RecordingProcessState.error,
        errorMessage: 'Failed to reset: $e',
      );
    }
  }

  // MÃ©thode de fallback pour calculer la durÃ©e basÃ©e sur la taille du fichier
  // Note: Cette mÃ©thode n'est prÃ©cise que pour les fichiers WAV non compressÃ©s
  // Elle est maintenant utilisÃ©e uniquement si le temps rÃ©el n'est pas disponible
  double _calculateDuration(int fileSizeBytes) {
    // Estimation approximative : 16kHz, 16-bit, mono
    // 16000 samples/sec * 2 bytes/sample = 32000 bytes/sec
    return fileSizeBytes / 32000.0;
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
