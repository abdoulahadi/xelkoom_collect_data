import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import 'dart:async';

enum PermissionResult { granted, denied, permanentlyDenied, error }

class PermissionInfo {
  final PermissionResult result;
  final String message;
  final bool needsSettings;

  const PermissionInfo({
    required this.result,
    required this.message,
    this.needsSettings = false,
  });
}

// Cache for permission results to avoid redundant checks
class _PermissionCache {
  static PermissionInfo? _microphonePermission;
  static PermissionInfo? _storagePermission;

  static void setMicrophonePermission(PermissionInfo info) =>
      _microphonePermission = info;
  static void setStoragePermission(PermissionInfo info) =>
      _storagePermission = info;

  static PermissionInfo? getMicrophonePermission() => _microphonePermission;
  static PermissionInfo? getStoragePermission() => _storagePermission;

  static void clearCache() {
    _microphonePermission = null;
    _storagePermission = null;
  }
}

class PermissionService {
  // Only log in debug mode
  static bool _debugMode = false;

  static void _log(String message, {String name = 'PermissionService'}) {
    if (_debugMode) {
      developer.log(message, name: name);
    }
  }

  static Future<PermissionInfo> requestMicrophonePermission() async {
    // Check cache first
    final cached = _PermissionCache.getMicrophonePermission();
    if (cached != null) return cached;

    try {
      // Check if permission is already granted
      PermissionStatus status = await Permission.microphone.status;

      _log('Current microphone permission status: $status');

      if (status.isGranted) {
        final result = const PermissionInfo(
          result: PermissionResult.granted,
          message: 'Permission microphone accordée',
        );
        _PermissionCache.setMicrophonePermission(result);
        return result;
      }

      if (status.isDenied) {
        // Request permission
        status = await Permission.microphone.request();
        _log('Permission request result: $status');

        if (status.isGranted) {
          final result = const PermissionInfo(
            result: PermissionResult.granted,
            message: 'Permission microphone accordée',
          );
          _PermissionCache.setMicrophonePermission(result);
          return result;
        } else if (status.isPermanentlyDenied) {
          final result = const PermissionInfo(
            result: PermissionResult.permanentlyDenied,
            message:
                'L\'accès au microphone est définitivement refusé. Vous devez l\'autoriser dans les paramètres.',
            needsSettings: true,
          );
          _PermissionCache.setMicrophonePermission(result);
          return result;
        } else {
          final result = const PermissionInfo(
            result: PermissionResult.denied,
            message:
                'Permission microphone refusée. L\'enregistrement audio nécessite l\'accès au microphone.',
          );
          _PermissionCache.setMicrophonePermission(result);
          return result;
        }
      }

      if (status.isPermanentlyDenied) {
        _log('Microphone permission permanently denied');
        final result = const PermissionInfo(
          result: PermissionResult.permanentlyDenied,
          message:
              'L\'accès au microphone est définitivement refusé. Vous devez l\'autoriser dans les paramètres.',
          needsSettings: true,
        );
        _PermissionCache.setMicrophonePermission(result);
        return result;
      }

      final result = const PermissionInfo(
        result: PermissionResult.denied,
        message: 'Permission microphone non disponible',
      );
      _PermissionCache.setMicrophonePermission(result);
      return result;
    } catch (e) {
      _log('Error requesting microphone permission: $e');
      final result = PermissionInfo(
        result: PermissionResult.error,
        message: 'Erreur lors de la demande de permission: $e',
      );
      _PermissionCache.setMicrophonePermission(result);
      return result;
    }
  }

  static Future<PermissionInfo> requestStoragePermission() async {
    // Check cache first
    final cached = _PermissionCache.getStoragePermission();
    if (cached != null) return cached;

    try {
      _log('Checking storage permission...');

      // For Android 13+ (API 33+), WRITE_EXTERNAL_STORAGE permission is deprecated
      // For our use case (files in app folder), we don't need it

      PermissionStatus status;
      try {
        status = await Permission.storage.status;
        _log('Storage permission status: $status');
      } catch (e) {
        // If permission is not supported (Android 13+), consider it granted
        _log('Storage permission not supported on this Android version: $e');
        final result = const PermissionInfo(
          result: PermissionResult.granted,
          message:
              'Permission stockage non requise sur cette version d\'Android',
        );
        _PermissionCache.setStoragePermission(result);
        return result;
      }

      if (status.isGranted || status.isLimited) {
        final result = const PermissionInfo(
          result: PermissionResult.granted,
          message: 'Permission stockage accordée',
        );
        _PermissionCache.setStoragePermission(result);
        return result;
      }

      if (status.isDenied) {
        try {
          status = await Permission.storage.request();
          _log('Storage permission request result: $status');

          if (status.isGranted || status.isLimited) {
            final result = const PermissionInfo(
              result: PermissionResult.granted,
              message: 'Permission stockage accordée',
            );
            _PermissionCache.setStoragePermission(result);
            return result;
          } else if (status.isPermanentlyDenied) {
            // Pour notre app, le stockage n'est pas critique, on peut continuer
            final result = const PermissionInfo(
              result: PermissionResult.granted,
              message:
                  'L\'application utilisera le stockage interne uniquement.',
            );
            _PermissionCache.setStoragePermission(result);
            return result;
          } else {
            // Pour notre app, le stockage n'est pas critique, on peut continuer
            final result = const PermissionInfo(
              result: PermissionResult.granted,
              message:
                  'L\'application utilisera le stockage interne uniquement.',
            );
            _PermissionCache.setStoragePermission(result);
            return result;
          }
        } catch (e) {
          // Si la demande échoue (Android 13+), considérer comme non nécessaire
          _log('Storage permission request failed (probably Android 13+): $e');
          final result = const PermissionInfo(
            result: PermissionResult.granted,
            message:
                'Permission stockage non requise sur cette version d\'Android',
          );
          _PermissionCache.setStoragePermission(result);
          return result;
        }
      }

      if (status.isPermanentlyDenied) {
        _log('Storage permission permanently denied');
        // Même si refusée, on peut continuer avec le stockage interne
        final result = const PermissionInfo(
          result: PermissionResult.granted,
          message: 'L\'application utilisera le stockage interne uniquement.',
        );
        _PermissionCache.setStoragePermission(result);
        return result;
      }

      // Par défaut, autoriser (stockage interne disponible)
      final result = const PermissionInfo(
        result: PermissionResult.granted,
        message: 'Utilisation du stockage interne de l\'application',
      );
      _PermissionCache.setStoragePermission(result);
      return result;
    } catch (e) {
      _log('Error requesting storage permission: $e');
      // En cas d'erreur, on peut toujours utiliser le stockage interne
      final result = const PermissionInfo(
        result: PermissionResult.granted,
        message: 'Utilisation du stockage interne de l\'application',
      );
      _PermissionCache.setStoragePermission(result);
      return result;
    }
  }

  // Process permissions in a separate isolate to avoid blocking UI
  static Future<Map<String, PermissionInfo>> requestAllPermissions() async {
    try {
      // Fetch permissions in parallel
      final micPermission = requestMicrophonePermission();
      final storagePermission = requestStoragePermission();

      // Wait for both permissions
      final results = await Future.wait([micPermission, storagePermission]);

      final permissionsMap = {'microphone': results[0], 'storage': results[1]};

      _log(
        'All permissions requested: mic=${results[0].result}, storage=${results[1].result}',
      );

      return permissionsMap;
    } catch (e) {
      _log('Error in requestAllPermissions: $e');
      return {
        'microphone': PermissionInfo(
          result: PermissionResult.error,
          message: 'Error requesting permissions: $e',
        ),
        'storage': const PermissionInfo(
          result: PermissionResult.granted, // Default to using internal storage
          message: 'Using app internal storage',
        ),
      };
    }
  }

  static Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      _log('Error opening app settings: $e');
    }
  }

  // Clear permission cache (useful when testing)
  static void clearCache() {
    _PermissionCache.clearCache();
  }
}
