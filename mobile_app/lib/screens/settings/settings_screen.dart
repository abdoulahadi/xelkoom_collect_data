import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../legal/terms_of_service_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../help/help_screen.dart';
import '../tutorial/tutorial_screen.dart';

// Provider pour les paramètres de l'application
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});

class AppSettings {
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool autoUpload;
  final String audioQuality;
  final String language;

  const AppSettings({
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.autoUpload = true,
    this.audioQuality = 'high',
    this.language = 'fr',
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? autoUpload,
    String? audioQuality,
    String? language,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      autoUpload: autoUpload ?? this.autoUpload,
      audioQuality: audioQuality ?? this.audioQuality,
      language: language ?? this.language,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  void updateNotifications(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
  }

  void updateSound(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
  }

  void updateVibration(bool enabled) {
    state = state.copyWith(vibrationEnabled: enabled);
  }

  void updateAutoUpload(bool enabled) {
    state = state.copyWith(autoUpload: enabled);
  }

  void updateAudioQuality(String quality) {
    state = state.copyWith(audioQuality: quality);
  }

  void updateLanguage(String language) {
    state = state.copyWith(language: language);
  }

  void resetToDefaults() {
    state = const AppSettings();
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Compte
            _buildSectionHeader('Compte'),
            _buildAccountSection(context, authState.user?.username),

            const SizedBox(height: 24),

            // Section Enregistrement
            _buildSectionHeader('Enregistrement'),
            _buildRecordingSection(context, ref, settings),

            const SizedBox(height: 24),

            // Section Notifications
            // _buildSectionHeader('Notifications'),
            // _buildNotificationSection(context, ref, settings),
            const SizedBox(height: 24),

            // Section Application
            _buildSectionHeader('Application'),
            _buildAppSection(context, ref, settings),

            const SizedBox(height: 24),

            // Section Confidentialité et Légal
            _buildSectionHeader('Confidentialité et Légal'),
            _buildLegalSection(context),

            const SizedBox(height: 24),

            // Section Support
            _buildSectionHeader('Support'),
            _buildSupportSection(context),

            const SizedBox(height: 24),

            // Section À propos
            _buildSectionHeader('À propos'),
            _buildAboutSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E88E5),
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, String? username) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF1E88E5)),
            title: const Text('Nom d\'utilisateur'),
            subtitle: Text(username ?? 'Non défini'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Naviguer vers l'écran de profil pour modifier
              Navigator.of(context).pop(); // Fermer les paramètres
              // L'utilisateur peut aller dans Profil depuis la navigation
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.security, color: Colors.green),
            title: const Text('Sécurité du compte'),
            subtitle: const Text('Gérer la sécurité de votre compte'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showSecurityDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingSection(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.cloud_upload, color: Color(0xFF1E88E5)),
            title: const Text('Upload automatique'),
            subtitle: const Text('Envoyer automatiquement les enregistrements'),
            value: settings.autoUpload,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateAutoUpload(value);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.high_quality, color: Colors.purple),
            title: const Text('Qualité audio'),
            subtitle: Text(_getAudioQualityLabel(settings.audioQuality)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap:
                () => _showAudioQualityDialog(
                  context,
                  ref,
                  settings.audioQuality,
                ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.folder, color: Colors.orange),
            title: const Text('Stockage local'),
            subtitle: const Text('Gérer les fichiers stockés localement'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showStorageDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSection(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF1E88E5)),
            title: const Text('Langue'),
            subtitle: Text(_getLanguageLabel(settings.language)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showLanguageDialog(context, ref, settings.language),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.palette, color: Colors.pink),
            title: const Text('Thème'),
            subtitle: const Text('Apparence de l\'application'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showThemeDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.green),
            title: const Text('Réinitialiser les paramètres'),
            subtitle: const Text('Restaurer les paramètres par défaut'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showResetDialog(context, ref),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.school, color: Colors.blue),
            title: const Text('Revoir le tutoriel'),
            subtitle: const Text('Relancer la présentation de l\'app'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TutorialScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.green),
            title: const Text('Politique de confidentialité'),
            subtitle: const Text('Protection de vos données'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description, color: Color(0xFF1E88E5)),
            title: const Text('Conditions d\'utilisation'),
            subtitle: const Text('Conforme au Code Numérique du Sénégal'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.shield, color: Colors.orange),
            title: const Text('Permissions'),
            subtitle: const Text('Gérer les permissions de l\'app'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showPermissionsDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help, color: Color(0xFF1E88E5)),
            title: const Text('Centre d\'aide'),
            subtitle: const Text('FAQ et guide d\'utilisation'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.feedback, color: Colors.blue),
            title: const Text('Feedback'),
            subtitle: const Text('Nous faire part de vos retours'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showFeedbackDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.red),
            title: const Text('Signaler un problème'),
            subtitle: const Text('Rapporter un bug ou un dysfonctionnement'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showBugReportDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info, color: Color(0xFF1E88E5)),
            title: const Text('À propos de Xelkoom'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showAboutDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.update, color: Colors.green),
            title: const Text('Vérifier les mises à jour'),
            subtitle: const Text('Rechercher une nouvelle version'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _checkForUpdates(context),
          ),
        ],
      ),
    );
  }

  String _getAudioQualityLabel(String quality) {
    switch (quality) {
      case 'low':
        return 'Basse (économise l\'espace)';
      case 'medium':
        return 'Moyenne (équilibrée)';
      case 'high':
        return 'Haute (meilleure qualité)';
      default:
        return 'Haute';
    }
  }

  String _getLanguageLabel(String language) {
    switch (language) {
      case 'fr':
        return 'Français';
      case 'wo':
        return 'Wolof';
      case 'en':
        return 'English';
      default:
        return 'Français';
    }
  }

  void _showAudioQualityDialog(
    BuildContext context,
    WidgetRef ref,
    String currentQuality,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Qualité audio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Basse'),
                subtitle: const Text('Économise l\'espace de stockage'),
                value: 'low',
                groupValue: currentQuality,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateAudioQuality(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Moyenne'),
                subtitle: const Text('Équilibre qualité/taille'),
                value: 'medium',
                groupValue: currentQuality,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateAudioQuality(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Haute'),
                subtitle: const Text('Meilleure qualité (recommandé)'),
                value: 'high',
                groupValue: currentQuality,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateAudioQuality(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    String currentLanguage,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Langue de l\'application'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Français'),
                value: 'fr',
                groupValue: currentLanguage,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateLanguage(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Wolof'),
                value: 'wo',
                groupValue: currentLanguage,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateLanguage(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'en',
                groupValue: currentLanguage,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateLanguage(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sécurité du compte'),
          content: const Text(
            'Votre compte est protégé par un mot de passe sécurisé. '
            'Toutes vos données sont chiffrées et stockées en sécurité.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showStorageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Stockage local'),
          content: const Text(
            'Vos enregistrements sont temporairement stockés localement '
            'avant d\'être envoyés au serveur. Vous pouvez nettoyer le cache '
            'pour libérer de l\'espace.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implémenter le nettoyage du cache
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Cache nettoyé')));
              },
              child: const Text('Nettoyer'),
            ),
          ],
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thème'),
          content: const Text(
            'Le thème sombre sera disponible dans une prochaine mise à jour.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Réinitialiser les paramètres'),
          content: const Text(
            'Êtes-vous sûr de vouloir restaurer tous les paramètres par défaut ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                // Reset to default settings
                ref.read(settingsProvider.notifier).resetToDefaults();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paramètres réinitialisés')),
                );
              },
              child: const Text('Réinitialiser'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Permissions utilisées par l\'application :'),
              SizedBox(height: 12),
              Text('• Microphone : Pour enregistrer votre voix'),
              Text('• Stockage : Pour sauvegarder les enregistrements'),
              Text('• Internet : Pour synchroniser avec le serveur'),
              Text('• Notifications : Pour vous tenir informé'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Feedback'),
          content: const Text(
            'Nous aimerions connaître votre avis sur l\'application !\n\n'
            'Contactez-nous à : feedback@xelkoom.sn',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showBugReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Signaler un problème'),
          content: const Text(
            'Rencontrez-vous un problème avec l\'application ?\n\n'
            'Décrivez le problème et envoyez-nous un email à :\n'
            'support@xelkoom.sn',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('À propos de Xelkoom'),
          content: const Text(
            'Xelkoom Data Collection v1.0.0\n\n'
            'Application de collecte de données vocales pour le développement '
            'de technologies TTS en langue Wolof.\n\n'
            'Développé conformément au Code Numérique du Sénégal.\n\n'
            '© 2025 Xelkoom Project',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _checkForUpdates(BuildContext context) {
    // Simuler une vérification de mise à jour
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Flexible(child: Text('Vérification des mises à jour...')),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Mises à jour'),
            content: const Text(
              'Vous utilisez la dernière version de l\'application.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }
}
