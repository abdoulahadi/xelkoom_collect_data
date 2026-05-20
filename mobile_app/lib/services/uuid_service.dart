import 'package:uuid/uuid.dart';

/// Service pour gérer les UUIDs dans l'application
class UuidService {
  static const Uuid _uuid = Uuid();

  /// Génère un nouvel UUID v4
  static String generate() {
    return _uuid.v4();
  }

  /// Valide qu'une chaîne est un UUID valide
  static bool isValid(String uuid) {
    try {
      // Un UUID valide doit avoir le format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
      final RegExp uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );
      return uuidRegex.hasMatch(uuid);
    } catch (e) {
      return false;
    }
  }

  /// Génère un UUID pour une nouvelle session d'enregistrement
  static String generateSessionId() {
    return generate();
  }

  /// Génère un UUID pour un fichier temporaire
  static String generateTempFileId() {
    return generate();
  }

  /// Convertit un potentiel ID legacy (int) en String
  /// Utile pendant la transition vers UUID
  static String ensureString(dynamic id) {
    if (id is String) {
      return id;
    } else if (id is int) {
      return id.toString();
    } else {
      return id.toString();
    }
  }
}
