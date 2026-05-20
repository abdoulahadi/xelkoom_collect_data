import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de Confidentialité'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Introduction',
              'Cette politique de confidentialité décrit comment Xelkoom collecte, utilise et protège vos données personnelles conformément au Code Numérique du Sénégal et aux standards internationaux de protection des données.',
            ),

            _buildSection(
              '1. Responsable du Traitement',
              'Xelkoom est le responsable du traitement de vos données personnelles. Nous nous engageons à respecter votre vie privée et à protéger vos données conformément à la réglementation en vigueur au Sénégal.',
            ),

            _buildSection(
              '2. Données Collectées',
              'Nous collectons les données suivantes :\n\n'
                  '• Données d\'identification : nom d\'utilisateur, email\n'
                  '• Données démographiques : âge, genre (optionnel)\n'
                  '• Enregistrements vocaux en langue Wolof\n'
                  '• Données techniques : adresse IP, type d\'appareil\n'
                  '• Données d\'usage : statistiques d\'utilisation de l\'app',
            ),

            _buildSection(
              '3. Finalités du Traitement',
              'Vos données sont traitées pour :\n\n'
                  '• La création et gestion de votre compte utilisateur\n'
                  '• Le développement de modèles de synthèse vocale\n'
                  '• L\'amélioration de l\'application\n'
                  '• La recherche académique en traitement des langues\n'
                  '• Le respect de nos obligations légales',
            ),

            _buildSection(
              '4. Base Légale du Traitement',
              'Conformément à l\'article 431-3 du Code Numérique du Sénégal, le traitement de vos données repose sur :\n\n'
                  '• Votre consentement libre et éclairé\n'
                  '• L\'intérêt légitime pour la recherche scientifique\n'
                  '• L\'exécution d\'une mission d\'intérêt public (promotion des langues nationales)',
            ),

            _buildSection(
              '5. Partage des Données',
              'Vos données ne sont pas vendues ou louées à des tiers. Elles peuvent être partagées uniquement :\n\n'
                  '• Avec des partenaires de recherche académique (données anonymisées)\n'
                  '• Avec les autorités compétentes si requis par la loi\n'
                  '• Avec des prestataires techniques sous contrat de confidentialité',
            ),

            _buildSection(
              '6. Sécurité des Données',
              'Nous mettons en place des mesures de sécurité robustes :\n\n'
                  '• Chiffrement des données sensibles\n'
                  '• Authentification forte des utilisateurs\n'
                  '• Contrôle d\'accès strict aux serveurs\n'
                  '• Surveillance continue des systèmes\n'
                  '• Formation du personnel à la sécurité',
            ),

            _buildSection(
              '7. Conservation des Données',
              'Durées de conservation :\n\n'
                  '• Données de compte : pendant toute la durée d\'utilisation + 3 ans\n'
                  '• Enregistrements vocaux : anonymisés et conservés pour la recherche\n'
                  '• Logs techniques : 12 mois maximum\n'
                  '• Vous pouvez demander la suppression à tout moment',
            ),

            _buildSection(
              '8. Vos Droits',
              'Vous disposez des droits suivants :\n\n'
                  '• Droit d\'accès à vos données\n'
                  '• Droit de rectification\n'
                  '• Droit d\'effacement (droit à l\'oubli)\n'
                  '• Droit à la portabilité\n'
                  '• Droit d\'opposition\n'
                  '• Droit de retrait du consentement',
            ),

            _buildSection(
              '9. Transferts Internationaux',
              'Vos données sont hébergées au Sénégal. En cas de transfert vers d\'autres pays, nous nous assurons d\'un niveau de protection adéquat conformément aux standards internationaux.',
            ),

            _buildSection(
              '10. Cookies et Technologies Similaires',
              'L\'application utilise des technologies de suivi pour :\n\n'
                  '• Maintenir votre session utilisateur\n'
                  '• Améliorer les performances\n'
                  '• Analyser l\'usage de l\'application\n'
                  '• Vous pouvez gérer ces préférences dans les paramètres',
            ),

            _buildSection(
              '11. Contact et Réclamations',
              'Pour exercer vos droits ou pour toute question :\n\n'
                  'Email : privacy@xelkoom.sn\n'
                  'Adresse : [Adresse au Sénégal]\n\n'
                  'Autorité de contrôle :\n'
                  'Commission des Données Personnelles (CDP) du Sénégal',
            ),

            const SizedBox(height: 32),

            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.privacy_tip,
                      color: Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Votre Vie Privée, Notre Priorité',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nous nous engageons à protéger votre vie privée et à utiliser vos données de manière transparente et responsable.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Dernière mise à jour : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E88E5),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
