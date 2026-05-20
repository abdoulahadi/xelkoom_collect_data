import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/recording.dart';

class RecordingsHistoryScreen extends ConsumerStatefulWidget {
  const RecordingsHistoryScreen({super.key});

  @override
  ConsumerState<RecordingsHistoryScreen> createState() =>
      _RecordingsHistoryScreenState();
}

class _RecordingsHistoryScreenState
    extends ConsumerState<RecordingsHistoryScreen> {
  final List<Recording> _recordings = [];
  bool _isLoading = true;
  String? _error;
  int _skip = 0;
  final int _limit = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings({bool refresh = false}) async {
    if (refresh) {
      _skip = 0;
      _recordings.clear();
      _hasMore = true;
    }

    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final newRecordings = await apiService.getMyRecordings(
        skip: _skip,
        limit: _limit,
      );

      setState(() {
        if (refresh) {
          _recordings.clear();
        }
        _recordings.addAll(newRecordings);
        _skip += newRecordings.length;
        _hasMore = newRecordings.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes enregistrements'), elevation: 0),
      body: RefreshIndicator(
        onRefresh: () => _loadRecordings(refresh: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _recordings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _recordings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadRecordings(refresh: true),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_recordings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucun enregistrement',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous n\'avez pas encore d\'enregistrements.\nCommencez à enregistrer pour les voir ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _recordings.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _recordings.length) {
          // Loading indicator for pagination
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final recording = _recordings[index];
        return _buildRecordingTile(recording);
      },
    );
  }

  Widget _buildRecordingTile(Recording recording) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildStatusIcon(recording.status),
        title: Text(
          'Enregistrement #${recording.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recording.duration != null)
              Text('Durée: ${recording.duration!.toStringAsFixed(1)}s'),
            Text(
              'Créé: ${_formatDate(recording.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: _buildStatusChip(recording.status),
        onTap: () => _showRecordingDetails(recording),
      ),
    );
  }

  Widget _buildStatusIcon(RecordingStatus status) {
    switch (status) {
      case RecordingStatus.pending:
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      case RecordingStatus.validated:
        return const Icon(Icons.check_circle, color: Colors.green);
      case RecordingStatus.rejected:
        return const Icon(Icons.cancel, color: Colors.red);
    }
  }

  Widget _buildStatusChip(RecordingStatus status) {
    Color color;
    String label;

    switch (status) {
      case RecordingStatus.pending:
        color = Colors.orange;
        label = 'En attente';
        break;
      case RecordingStatus.validated:
        color = Colors.green;
        label = 'Validé';
        break;
      case RecordingStatus.rejected:
        color = Colors.red;
        label = 'Rejeté';
        break;
    }

    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showRecordingDetails(Recording recording) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Enregistrement #${recording.id}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Statut', _getStatusText(recording.status)),
                if (recording.duration != null)
                  _buildDetailRow(
                    'Durée',
                    '${recording.duration!.toStringAsFixed(1)} secondes',
                  ),
                if (recording.fileSize != null)
                  _buildDetailRow(
                    'Taille',
                    '${recording.fileSize!.toStringAsFixed(2)} MB',
                  ),
                if (recording.sampleRate != null)
                  _buildDetailRow(
                    'Fréquence',
                    '${recording.sampleRate!.toInt()} Hz',
                  ),
                if (recording.qualityScore != null)
                  _buildDetailRow(
                    'Score qualité',
                    '${(recording.qualityScore! * 100).toInt()}%',
                  ),
                _buildDetailRow('Créé le', _formatDate(recording.createdAt)),
                if (recording.adminNotes != null &&
                    recording.adminNotes!.isNotEmpty)
                  _buildDetailRow('Notes admin', recording.adminNotes!),
              ],
            ),
            actions: [
              if (recording.status == RecordingStatus.pending)
                TextButton(
                  onPressed: () => _deleteRecording(recording),
                  child: const Text(
                    'Supprimer',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getStatusText(RecordingStatus status) {
    switch (status) {
      case RecordingStatus.pending:
        return 'En attente de validation';
      case RecordingStatus.validated:
        return 'Validé par un modérateur';
      case RecordingStatus.rejected:
        return 'Rejeté par un modérateur';
    }
  }

  Future<void> _deleteRecording(Recording recording) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer l\'enregistrement'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cet enregistrement ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.deleteRecording(recording.id);

        setState(() {
          _recordings.remove(recording);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enregistrement supprimé')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
        }
      }
    }

    if (mounted) {
      Navigator.of(context).pop(); // Close details dialog
    }
  }
}
