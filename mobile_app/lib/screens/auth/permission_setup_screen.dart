import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/permission_service.dart';

class PermissionSetupScreen extends ConsumerStatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionSetupScreen({super.key, required this.onPermissionsGranted});

  @override
  ConsumerState<PermissionSetupScreen> createState() =>
      _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends ConsumerState<PermissionSetupScreen> {
  Map<String, PermissionInfo>? _permissionStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await PermissionService.requestAllPermissions();
      setState(() {
        _permissionStatus = results;
      });

      // Si toutes les permissions sont accordées, continuer automatiquement
      final allGranted = results.values.every(
        (info) => info.result == PermissionResult.granted,
      );

      if (allGranted) {
        widget.onPermissionsGranted();
      }
    } catch (e) {
      print('Error checking permissions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Spacer pour centrer le contenu sur grand écran
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),

              // Icon et titre
              Icon(
                Icons.security,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),

              const SizedBox(height: 24),

              Text(
                'Configuration des permissions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Xelkoom a besoin de certaines permissions pour fonctionner correctement.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // État des permissions - version simplifiée
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Vérification des permissions...'),
              ] else ...[
                // Affichage simplifié des permissions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (_permissionStatus != null) ...[
                          // Affichage simple du statut
                          for (var entry in _permissionStatus!.entries)
                            _buildSimplePermissionItem(
                              entry.key,
                              entry.value.result == PermissionResult.granted,
                            ),
                        ] else ...[
                          const Text('Permissions en attente de vérification'),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Explications des permissions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Permissions nécessaires :',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPermissionExplanation(
                        Icons.mic,
                        'Microphone',
                        'Pour enregistrer votre voix lors de la lecture des phrases en Wolof.',
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildPermissionExplanation(
                        Icons.storage,
                        'Stockage',
                        'Pour sauvegarder temporairement les enregistrements avant envoi.',
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Boutons d'action - version simplifiée
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_permissionStatus != null) {
                      // Vérifier les permissions existantes
                      _checkCurrentPermissions();
                    } else {
                      // Demander les permissions
                      _requestPermissions();
                    }
                  },
                  child: const Text('Configurer les permissions'),
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    // Bypass des permissions - continuer quand même
                    print('Bypassing permissions check...');
                    widget.onPermissionsGranted();
                  },
                  child: const Text(
                    'Continuer sans configurer maintenant',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

              // Spacer pour équilibrer l'espace en bas
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionExplanation(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimplePermissionItem(String permissionName, bool isGranted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.cancel,
            color: isGranted ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              permissionName == 'microphone' ? 'Microphone' : 'Stockage',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            isGranted ? 'Accordée' : 'Refusée',
            style: TextStyle(
              color: isGranted ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await PermissionService.requestAllPermissions();
      setState(() {
        _permissionStatus = results;
      });

      // Si toutes les permissions sont accordées, continuer automatiquement
      final allGranted = results.values.every(
        (info) => info.result == PermissionResult.granted,
      );

      if (allGranted) {
        widget.onPermissionsGranted();
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      // En cas d'erreur, permettre quand même de continuer
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la demande de permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
