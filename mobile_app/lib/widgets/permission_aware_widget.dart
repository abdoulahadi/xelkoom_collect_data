import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/permission_service.dart';
import '../widgets/permission_manager.dart';

class PermissionAwareWidget extends ConsumerStatefulWidget {
  final Widget child;
  final Widget Function(
    BuildContext context,
    Map<String, PermissionInfo> permissions,
  )?
  permissionDeniedBuilder;
  final bool checkOnBuild;

  const PermissionAwareWidget({
    super.key,
    required this.child,
    this.permissionDeniedBuilder,
    this.checkOnBuild = true,
  });

  @override
  ConsumerState<PermissionAwareWidget> createState() =>
      _PermissionAwareWidgetState();
}

class _PermissionAwareWidgetState extends ConsumerState<PermissionAwareWidget> {
  Map<String, PermissionInfo>? _permissions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.checkOnBuild) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final permissions = await PermissionService.requestAllPermissions();
      if (mounted) {
        setState(() {
          _permissions = permissions;
        });
      }
    } catch (e) {
      print('Error checking permissions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool get _hasPermissions {
    if (_permissions == null) return false;
    final micPermission = _permissions!['microphone'];
    return micPermission?.result == PermissionResult.granted;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Vérification des permissions...'),
          ],
        ),
      );
    }

    if (!_hasPermissions && _permissions != null) {
      if (widget.permissionDeniedBuilder != null) {
        return widget.permissionDeniedBuilder!(context, _permissions!);
      }

      return _buildDefaultPermissionDenied();
    }

    return widget.child;
  }

  Widget _buildDefaultPermissionDenied() {
    final micPermission = _permissions!['microphone'];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_off, size: 80, color: Colors.red[300]),

            const SizedBox(height: 24),

            const Text(
              'Permission microphone requise',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              micPermission?.message ??
                  'L\'accès au microphone est nécessaire pour enregistrer votre voix.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            if (micPermission?.needsSettings == true) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await PermissionService.openSettings();
                  // Revérifier après retour des paramètres
                  await Future.delayed(const Duration(seconds: 1));
                  _checkPermissions();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Ouvrir les paramètres'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              PermissionRequestButton(
                text: 'Autoriser le microphone',
                onPermissionsGranted: () {
                  _checkPermissions();
                },
                onPermissionsDenied: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Permission microphone requise pour l\'enregistrement',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                showExplanation: false,
                showResults: false,
              ),
            ],

            const SizedBox(height: 16),

            TextButton(
              onPressed: _checkPermissions,
              child: const Text('Vérifier à nouveau'),
            ),
          ],
        ),
      ),
    );
  }
}
