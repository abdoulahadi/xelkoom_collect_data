import 'package:flutter/material.dart';
import '../services/permission_service.dart';

class PermissionDialogs {
  /// Affiche un dialogue d'explication pour la permission microphone
  static Future<bool?> showMicrophonePermissionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mic, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(child: Text('Accès au microphone')),
            ],
          ),
          content: const Text(
            'Cette application a besoin d\'accéder à votre microphone pour enregistrer votre voix.\n\n'
            'Vos enregistrements nous aident à améliorer la technologie vocale en Wolof.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Refuser'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Autoriser'),
            ),
          ],
        );
      },
    );
  }

  /// Affiche un dialogue d'explication pour la permission stockage
  static Future<bool?> showStoragePermissionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.storage, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text('Accès au stockage')),
            ],
          ),
          content: const Text(
            'Cette application a besoin d\'accéder au stockage de votre appareil pour sauvegarder temporairement vos enregistrements.\n\n'
            'Les fichiers sont supprimés après envoi au serveur.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Refuser'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Autoriser'),
            ),
          ],
        );
      },
    );
  }

  /// Affiche un dialogue pour les permissions définitivement refusées
  static Future<bool?> showPermanentlyDeniedDialog(
    BuildContext context,
    String permissionName,
    String explanation,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text('Permission $permissionName requise')),
            ],
          ),
          content: Text(
            '$explanation\n\n'
            'Pour utiliser cette fonctionnalité, vous devez aller dans les paramètres de l\'application et autoriser manuellement cette permission.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ouvrir les paramètres'),
            ),
          ],
        );
      },
    );
  }

  /// Affiche un dialogue de résultat des permissions
  static Future<void> showPermissionResultDialog(
    BuildContext context,
    Map<String, PermissionInfo> results,
  ) {
    final hasErrors = results.values.any(
      (info) => info.result != PermissionResult.granted,
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                hasErrors ? Icons.warning : Icons.check_circle,
                color: hasErrors ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasErrors
                      ? 'Permissions incomplètes'
                      : 'Permissions accordées',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hasErrors) ...[
                const Text(
                  'Toutes les permissions nécessaires ont été accordées !',
                ),
              ] else ...[
                const Text('Certaines permissions sont manquantes :'),
                const SizedBox(height: 12),
                ...results.entries.map((entry) {
                  final permissionName = entry.key;
                  final info = entry.value;
                  final isGranted = info.result == PermissionResult.granted;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isGranted ? Icons.check : Icons.close,
                          color: isGranted ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            permissionName == 'microphone'
                                ? 'Microphone'
                                : 'Stockage',
                            style: TextStyle(
                              color: isGranted ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (results.values.any((info) => info.needsSettings)) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Certaines permissions doivent être accordées dans les paramètres.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ],
          ),
          actions: [
            if (results.values.any((info) => info.needsSettings)) ...[
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await PermissionService.openSettings();
                },
                child: const Text('Ouvrir les paramètres'),
              ),
            ],
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
