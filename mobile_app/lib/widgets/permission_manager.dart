import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import 'permission_dialogs.dart';

class PermissionManager {
  /// Demande les permissions avec un flow utilisateur complet
  static Future<bool> requestPermissionsWithUI(
    BuildContext context, {
    bool showExplanation = true,
    bool showResults = true,
  }) async {
    try {
      // Étape 1: Explication pour le microphone
      if (showExplanation) {
        final microphoneExplained =
            await PermissionDialogs.showMicrophonePermissionDialog(context);
        if (microphoneExplained != true) {
          // L'utilisateur a refusé l'explication
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'L\'accès au microphone est nécessaire pour enregistrer votre voix.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return false;
        }
      }

      // Étape 2: Demander la permission microphone
      final micResult = await PermissionService.requestMicrophonePermission();

      // Si le microphone est refusé définitivement, proposer d'aller aux paramètres
      if (micResult.result == PermissionResult.permanentlyDenied) {
        final openSettings =
            await PermissionDialogs.showPermanentlyDeniedDialog(
              context,
              'microphone',
              micResult.message,
            );

        if (openSettings == true) {
          await PermissionService.openSettings();
        }
        return false;
      }

      // Étape 3: Explication pour le stockage (si nécessaire)
      if (showExplanation && micResult.result == PermissionResult.granted) {
        final storageExplained =
            await PermissionDialogs.showStoragePermissionDialog(context);
        if (storageExplained != true) {
          // L'utilisateur peut continuer sans le stockage sur Android 13+
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Le stockage sera limité aux fichiers temporaires.',
              ),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }

      // Étape 4: Demander la permission stockage
      final storageResult = await PermissionService.requestStoragePermission();

      // Étape 5: Afficher les résultats
      final results = {'microphone': micResult, 'storage': storageResult};

      if (showResults) {
        await PermissionDialogs.showPermissionResultDialog(context, results);
      }

      // Retourner true si au moins le microphone est accordé
      return micResult.result == PermissionResult.granted;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la demande de permissions: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  /// Vérification rapide des permissions sans UI
  static Future<bool> checkPermissions() async {
    final micResult = await PermissionService.requestMicrophonePermission();
    return micResult.result == PermissionResult.granted;
  }

  /// Widget d'état des permissions pour l'affichage dans l'UI
  static Widget buildPermissionStatus(Map<String, PermissionInfo> permissions) {
    final micPermission = permissions['microphone'];
    final storagePermission = permissions['storage'];
    final micGranted = micPermission?.result == PermissionResult.granted;
    final storageGranted =
        storagePermission?.result == PermissionResult.granted;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'État des permissions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Microphone (critique)
            _buildPermissionRow(
              icon: micGranted ? Icons.check_circle : Icons.error,
              color: micGranted ? Colors.green : Colors.red,
              title: 'Microphone',
              subtitle:
                  micGranted
                      ? 'Accordée - Enregistrement possible'
                      : micPermission?.message ?? 'Refusée',
              isGranted: micGranted,
              isCritical: true,
            ),

            const SizedBox(height: 8),

            // Stockage (optionnel)
            _buildPermissionRow(
              icon: Icons.info_outline,
              color: Colors.blue,
              title: 'Stockage',
              subtitle:
                  storageGranted
                      ? 'Accordée - Accès complet au stockage'
                      : 'Stockage interne uniquement (suffisant pour l\'app)',
              isGranted: true, // Toujours considéré comme OK
              isCritical: false,
            ),

            if (!micGranted) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[600], size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Le microphone est requis pour enregistrer votre voix.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _buildPermissionRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isGranted,
    required bool isCritical,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color:
                          isCritical && !isGranted
                              ? Colors.red
                              : Colors.black87,
                    ),
                  ),
                  if (!isCritical) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'optionnel',
                        style: TextStyle(fontSize: 10, color: Colors.blue),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget Button pour demander les permissions
class PermissionRequestButton extends StatefulWidget {
  final VoidCallback? onPermissionsGranted;
  final VoidCallback? onPermissionsDenied;
  final String text;
  final bool showExplanation;
  final bool showResults;

  const PermissionRequestButton({
    super.key,
    this.onPermissionsGranted,
    this.onPermissionsDenied,
    this.text = 'Autoriser les permissions',
    this.showExplanation = true,
    this.showResults = true,
  });

  @override
  State<PermissionRequestButton> createState() =>
      _PermissionRequestButtonState();
}

class _PermissionRequestButtonState extends State<PermissionRequestButton> {
  bool _isLoading = false;

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await PermissionManager.requestPermissionsWithUI(
        context,
        showExplanation: widget.showExplanation,
        showResults: widget.showResults,
      );

      if (granted) {
        widget.onPermissionsGranted?.call();
      } else {
        widget.onPermissionsDenied?.call();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _requestPermissions,
      icon:
          _isLoading
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.security),
      label: Text(_isLoading ? 'Vérification...' : widget.text),
    );
  }
}
