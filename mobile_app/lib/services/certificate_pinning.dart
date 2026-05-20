import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:developer' as developer;

/// SEC-011: Certificate pinning for MITM protection.
///
/// Configure SHA-256 fingerprints of the server's leaf certificate.
/// To get the fingerprint of a certificate:
///   openssl s_client -connect host:443 < /dev/null 2>/dev/null \
///     | openssl x509 -noout -fingerprint -sha256
///
/// Pass fingerprints via --dart-define=CERT_FINGERPRINTS=sha256/AA:BB:...;sha256/CC:DD:...
class CertificatePinning {
  // Configurable via --dart-define at build time
  static const String _rawFingerprints = String.fromEnvironment(
    'CERT_FINGERPRINTS',
    defaultValue: '',
  );

  /// Whether pinning is enabled (fingerprints were provided at build time).
  static bool get isEnabled => _rawFingerprints.isNotEmpty;

  static List<String> get _fingerprints =>
      _rawFingerprints.split(';').where((s) => s.isNotEmpty).toList();

  /// Apply certificate pinning to a Dio instance.
  /// Does nothing if no fingerprints are configured.
  static void apply(Dio dio) {
    if (!isEnabled) {
      developer.log(
        'Certificate pinning not configured (no CERT_FINGERPRINTS). '
        'Set via --dart-define=CERT_FINGERPRINTS=sha256/AA:BB:...',
        name: 'CertificatePinning',
      );
      return;
    }

    final adapter = dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      adapter.onHttpClientCreate = (client) {
        client.badCertificateCallback = _validateCertificate;
        return client;
      };
    }
    developer.log(
      'Certificate pinning enabled with ${_fingerprints.length} fingerprint(s)',
      name: 'CertificatePinning',
    );
  }

  static bool _validateCertificate(
    X509Certificate cert,
    String host,
    int port,
  ) {
    // Extract the SHA-256 fingerprint from the certificate
    final certFingerprint = cert.sha256Fingerprint;

    for (final pinned in _fingerprints) {
      final normalized =
          pinned.replaceFirst('sha256/', '').replaceAll(':', '').toLowerCase();
      final certNormalized = certFingerprint.replaceAll(':', '').toLowerCase();
      if (normalized == certNormalized) {
        return true;
      }
    }

    developer.log(
      'Certificate pinning FAILED for $host:$port. '
      'Fingerprint: $certFingerprint',
      name: 'CertificatePinning',
    );
    return false; // Reject the connection
  }
}

/// Extension to extract SHA-256 fingerprint from X509Certificate.
extension X509CertificateFingerprint on X509Certificate {
  String get sha256Fingerprint {
    // Compute SHA-256 digest of the DER-encoded certificate
    final digest = crypto.sha256.convert(der);
    return digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }
}
