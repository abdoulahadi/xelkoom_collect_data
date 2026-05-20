import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sentence_provider.dart';
import '../../providers/recording_provider.dart';
import '../../models/sentence.dart';
import '../../widgets/permission_aware_widget.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  @override
  void initState() {
    super.initState();
    // Charger la premiÃ¨re sentence au dÃ©marrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final _ = ref.refresh(refreshableSentenceProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sentenceAsync = ref.watch(refreshableSentenceProvider);
    final recordingState = ref.watch(recordingStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enregistrement'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nouvelle phrase',
            onPressed: () {
              ref.read(recordingStateProvider.notifier).reset();
              ref.read(reloadSentenceProvider.notifier).state++;
            },
          ),
        ],
      ),
      body: PermissionAwareWidget(
        child: Column(
          children: [
            // Section phrase Ã  enregistrer
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: sentenceAsync.when(
                  data: (sentence) => _buildSentenceDisplay(sentence),
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _buildErrorDisplay(error.toString()),
                ),
              ),
            ),

            // Section contrÃ´les d'enregistrement
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Indicateur visuel d'enregistrement
                      _buildRecordingIndicator(recordingState),

                      const SizedBox(height: 30),

                      // Boutons de contrÃ´le
                      _buildControlButtons(recordingState, sentenceAsync),

                      const SizedBox(height: 20),

                      // Informations sur l'Ã©tat
                      _buildStatusInfo(recordingState),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentenceDisplay(Sentence sentence) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.format_quote, size: 40, color: Colors.blue),
        const SizedBox(height: 16),
        Text(
          sentence.text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getDifficultyColor(sentence.difficultyLevel),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            sentence.difficultyLevel.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 40, color: Colors.red),
        const SizedBox(height: 16),
        Text(
          'Erreur lors du chargement de la phrase',
          style: TextStyle(
            fontSize: 16,
            color: Colors.red[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecordingIndicator(RecordingState recordingState) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getIndicatorColor(recordingState.status),
        boxShadow: [
          if (recordingState.status == RecordingProcessState.recording)
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
        ],
      ),
      child: Icon(
        _getIndicatorIcon(recordingState.status),
        size: 50,
        color: Colors.white,
      ),
    );
  }

  Widget _buildControlButtons(
    RecordingState recordingState,
    AsyncValue<Sentence> sentenceAsync,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Bouton Record/Stop
        ElevatedButton(
          onPressed: _getRecordButtonAction(recordingState),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                recordingState.status == RecordingProcessState.recording
                    ? Colors.red
                    : recordingState.status == RecordingProcessState.preparing
                    ? Colors.orange
                    : Colors.blue,
            minimumSize: const Size(120, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child:
              recordingState.status == RecordingProcessState.preparing
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_getRecordButtonText(recordingState.status)),
                    ],
                  )
                  : Text(_getRecordButtonText(recordingState.status)),
        ),

        // Bouton Play (visible seulement si enregistrement terminÃ©)
        if (recordingState.status == RecordingProcessState.stopped)
          ElevatedButton(
            onPressed:
                recordingState.isPlaying
                    ? () =>
                        ref.read(recordingStateProvider.notifier).stopPlayback()
                    : () =>
                        ref
                            .read(recordingStateProvider.notifier)
                            .playRecording(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(100, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Icon(
              recordingState.isPlaying ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
            ),
          ),

        // Bouton Upload (visible seulement si enregistrement terminÃ©)
        if (recordingState.status == RecordingProcessState.stopped)
          ElevatedButton(
            onPressed: () => _uploadRecording(sentenceAsync),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(100, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text('Envoyer'),
          ),
      ],
    );
  }

  Widget _buildStatusInfo(RecordingState recordingState) {
    String statusText = '';
    Color statusColor = Colors.grey;

    switch (recordingState.status) {
      case RecordingProcessState.idle:
        statusText = 'Appuyez sur le bouton pour commencer';
        break;
      case RecordingProcessState.preparing:
        statusText = 'PrÃ©paration de l\'enregistrement...';
        statusColor = Colors.orange;
        break;
      case RecordingProcessState.recording:
        statusText = 'Enregistrement en cours...';
        statusColor = Colors.red;
        break;
      case RecordingProcessState.stopped:
        statusText =
            recordingState.duration != null
                ? 'Enregistrement terminÃ© (${recordingState.duration!.toStringAsFixed(1)}s)'
                : 'Enregistrement terminÃ©';
        statusColor = Colors.green;
        break;
      case RecordingProcessState.playing:
        statusText = 'Lecture en cours...';
        statusColor = Colors.blue;
        break;
      case RecordingProcessState.uploading:
        statusText = 'Envoi en cours...';
        statusColor = Colors.orange;
        break;
      case RecordingProcessState.uploaded:
        statusText = 'Enregistrement envoyÃ© avec succÃ¨s !';
        statusColor = Colors.green;
        break;
      case RecordingProcessState.error:
        statusText = recordingState.errorMessage ?? 'Une erreur est survenue';
        statusColor = Colors.red;
        break;
    }

    return Column(
      children: [
        Text(
          statusText,
          style: TextStyle(
            fontSize: 16,
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),

        if (recordingState.status == RecordingProcessState.uploading ||
            recordingState.status == RecordingProcessState.recording)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: LinearProgressIndicator(),
          ),

        if (recordingState.status == RecordingProcessState.uploaded)
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: ElevatedButton(
              onPressed: () {
                ref.read(recordingStateProvider.notifier).reset();
                ref.read(reloadSentenceProvider.notifier).state++;
              },
              child: const Text('Nouvelle phrase'),
            ),
          ),

        if (recordingState.status == RecordingProcessState.error)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    ref.read(recordingStateProvider.notifier).clearError();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('RÃ©essayer'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  VoidCallback? _getRecordButtonAction(RecordingState recordingState) {
    switch (recordingState.status) {
      case RecordingProcessState.idle:
      case RecordingProcessState.stopped:
        return () => ref.read(recordingStateProvider.notifier).startRecording();
      case RecordingProcessState.recording:
        return () => ref.read(recordingStateProvider.notifier).stopRecording();
      case RecordingProcessState.preparing:
        return null; // DÃ©sactiver le bouton pendant la prÃ©paration
      default:
        return null;
    }
  }

  String _getRecordButtonText(RecordingProcessState status) {
    switch (status) {
      case RecordingProcessState.preparing:
        return 'PrÃ©paration...';
      case RecordingProcessState.recording:
        return 'ArrÃªter';
      default:
        return 'Enregistrer';
    }
  }

  Color _getIndicatorColor(RecordingProcessState status) {
    switch (status) {
      case RecordingProcessState.preparing:
        return Colors.orange;
      case RecordingProcessState.recording:
        return Colors.red;
      case RecordingProcessState.stopped:
      case RecordingProcessState.uploaded:
        return Colors.green;
      case RecordingProcessState.playing:
        return Colors.blue;
      case RecordingProcessState.uploading:
        return Colors.orange;
      case RecordingProcessState.error:
        return Colors.red[300]!;
      default:
        return Colors.grey;
    }
  }

  IconData _getIndicatorIcon(RecordingProcessState status) {
    switch (status) {
      case RecordingProcessState.preparing:
        return Icons.hourglass_empty;
      case RecordingProcessState.recording:
        return Icons.mic;
      case RecordingProcessState.stopped:
        return Icons.check;
      case RecordingProcessState.playing:
        return Icons.volume_up;
      case RecordingProcessState.uploading:
        return Icons.cloud_upload;
      case RecordingProcessState.uploaded:
        return Icons.cloud_done;
      case RecordingProcessState.error:
        return Icons.error;
      default:
        return Icons.mic_none;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Future<void> _uploadRecording(AsyncValue<Sentence> sentenceAsync) async {
    final sentence = sentenceAsync.asData?.value;
    if (sentence == null) return;

    final recording = await ref
        .read(recordingStateProvider.notifier)
        .uploadRecording(sentence);

    if (recording != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enregistrement envoyÃ© avec succÃ¨s !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
