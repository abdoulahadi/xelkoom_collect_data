import 'dart:io';
import 'dart:developer' as developer;
import '../services/audio_recorder_service.dart';
import '../services/permission_service.dart';

class AudioDebugHelper {
  static Future<Map<String, dynamic>> runFullDiagnostic() async {
    final Map<String, dynamic> diagnostic = {};

    try {
      developer.log(
        'Running full audio diagnostic...',
        name: 'AudioDebugHelper',
      );

      // 1. Vérifier la plateforme
      diagnostic['platform'] = Platform.operatingSystem;
      diagnostic['isAndroid'] = Platform.isAndroid;
      diagnostic['isIOS'] = Platform.isIOS;

      // 2. Vérifier les permissions
      final micPermission =
          await PermissionService.requestMicrophonePermission();
      diagnostic['microphonePermission'] = {
        'result': micPermission.result.toString(),
        'message': micPermission.message,
      };

      final storagePermission =
          await PermissionService.requestStoragePermission();
      diagnostic['storagePermission'] = {
        'result': storagePermission.result.toString(),
        'message': storagePermission.message,
      };

      // 3. Tester l'initialisation du service audio
      try {
        final audioService = AudioRecorderService();
        await audioService.initialize();
        diagnostic['audioServiceInitialized'] = true;

        // 4. Tester le microphone
        final micTest = await audioService.testMicrophone();
        diagnostic['microphoneTest'] = micTest;

        // 5. Tester différentes configurations d'enregistrement
        final configTest = await audioService.testRecordingConfigurations();
        diagnostic['recordingConfigurationTest'] = configTest;

        // 6. Récupérer les diagnostics du service
        final serviceDiagnostic = await audioService.diagnoseAudioSystem();
        diagnostic['audioServiceDiagnostic'] = serviceDiagnostic;

        await audioService.dispose();
      } catch (e) {
        diagnostic['audioServiceError'] = e.toString();
        diagnostic['audioServiceInitialized'] = false;
      }

      // 6. Informations sur l'appareil
      diagnostic['timestamp'] = DateTime.now().toIso8601String();

      developer.log(
        'Full diagnostic completed: $diagnostic',
        name: 'AudioDebugHelper',
      );

      return diagnostic;
    } catch (e) {
      diagnostic['diagnosticError'] = e.toString();
      developer.log('Error during diagnostic: $e', name: 'AudioDebugHelper');
      return diagnostic;
    }
  }

  static String formatDiagnosticReport(Map<String, dynamic> diagnostic) {
    final buffer = StringBuffer();
    buffer.writeln('=== AUDIO DIAGNOSTIC REPORT ===');
    buffer.writeln('Generated: ${diagnostic['timestamp'] ?? 'Unknown'}');
    buffer.writeln();

    buffer.writeln('Platform Information:');
    buffer.writeln('- Platform: ${diagnostic['platform'] ?? 'Unknown'}');
    buffer.writeln('- Is Android: ${diagnostic['isAndroid'] ?? 'Unknown'}');
    buffer.writeln('- Is iOS: ${diagnostic['isIOS'] ?? 'Unknown'}');
    buffer.writeln();

    buffer.writeln('Permissions:');
    final micPerm = diagnostic['microphonePermission'];
    if (micPerm != null) {
      buffer.writeln(
        '- Microphone: ${micPerm['result']} (${micPerm['message']})',
      );
    }
    final storagePerm = diagnostic['storagePermission'];
    if (storagePerm != null) {
      buffer.writeln(
        '- Storage: ${storagePerm['result']} (${storagePerm['message']})',
      );
    }
    buffer.writeln();

    buffer.writeln('Audio Service:');
    buffer.writeln(
      '- Initialized: ${diagnostic['audioServiceInitialized'] ?? 'Unknown'}',
    );
    buffer.writeln(
      '- Microphone Test: ${diagnostic['microphoneTest'] ?? 'Unknown'}',
    );

    if (diagnostic['audioServiceError'] != null) {
      buffer.writeln('- Service Error: ${diagnostic['audioServiceError']}');
    }
    buffer.writeln();

    if (diagnostic['audioServiceDiagnostic'] != null) {
      buffer.writeln('Detailed Audio Service Diagnostic:');
      final serviceDiag =
          diagnostic['audioServiceDiagnostic'] as Map<String, dynamic>;
      serviceDiag.forEach((key, value) {
        buffer.writeln('- $key: $value');
      });
      buffer.writeln();
    }

    if (diagnostic['diagnosticError'] != null) {
      buffer.writeln('Diagnostic Error: ${diagnostic['diagnosticError']}');
    }

    buffer.writeln('=== END REPORT ===');

    return buffer.toString();
  }

  static Future<void> printDiagnosticReport() async {
    final diagnostic = await runFullDiagnostic();
    final report = formatDiagnosticReport(diagnostic);

    // Print to console
    print(report);

    // Also log to developer console
    developer.log(report, name: 'AudioDebugHelper');
  }
}
