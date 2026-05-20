import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditions Générales d\'Utilisation'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Préambule',
              'Xelkoom est une application de collecte de données vocales développée en conformité avec le Code Numérique du Sénégal (Loi n°2020-05 du 10 février 2020) et les dispositions relatives à la protection des données personnelles.',
            ),

            _buildSection(
              '1. Objet de l\'Application',
              'L\'application Xelkoom a pour objectif la collecte de données vocales en langue Wolof pour le développement de technologies de synthèse vocale (Text-to-Speech). Cette initiative s\'inscrit dans la promotion des langues nationales du Sénégal et le développement de l\'intelligence artificielle en Afrique.',
            ),

            _buildSection(
              '2. Acceptation des Conditions',
              'En utilisant cette application, vous acceptez expressément ces conditions générales d\'utilisation. Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser l\'application.',
            ),

            _buildSection(
              '3. Protection des Données Personnelles',
              'Conformément à l\'article 431-1 du Code Numérique du Sénégal et au Règlement Général sur la Protection des Données (RGPD) :\n\n'
                  '• Vos données personnelles sont collectées de manière licite et transparente\n'
                  '• Vous disposez d\'un droit d\'accès, de rectification et de suppression\n'
                  '• Vos enregistrements vocaux sont anonymisés pour la recherche\n'
                  '• Aucune donnée n\'est partagée avec des tiers sans votre consentement\n'
                  '• Vous pouvez supprimer votre compte et toutes vos données à tout moment',
            ),

            _buildSection(
              '4. Utilisation des Enregistrements Vocaux',
              'Les enregistrements vocaux collectés sont utilisés exclusivement pour :\n\n'
                  '• Le développement de modèles de synthèse vocale en Wolof\n'
                  '• La recherche académique en traitement automatique des langues\n'
                  '• L\'amélioration des technologies d\'intelligence artificielle pour les langues africaines\n\n'
                  'Tous les enregistrements sont soumis à un processus de validation par nos modérateurs avant utilisation.',
            ),

            _buildSection(
              '5. Droits des Utilisateurs',
              'Conformément aux articles 431-5 à 431-7 du Code Numérique du Sénégal, vous bénéficiez des droits suivants :\n\n'
                  '• Droit à l\'information sur le traitement de vos données\n'
                  '• Droit d\'accès à vos données personnelles\n'
                  '• Droit de rectification des données inexactes\n'
                  '• Droit d\'effacement (droit à l\'oubli)\n'
                  '• Droit à la portabilité de vos données\n'
                  '• Droit d\'opposition au traitement',
            ),

            _buildSection(
              '6. Sécurité des Données',
              'Nous mettons en œuvre des mesures techniques et organisationnelles appropriées pour assurer la sécurité de vos données :\n\n'
                  '• Chiffrement des données en transit et au repos\n'
                  '• Authentification sécurisée des utilisateurs\n'
                  '• Accès limité aux données par le personnel autorisé\n'
                  '• Sauvegarde régulière des données\n'
                  '• Audit de sécurité périodique',
            ),

            _buildSection(
              '7. Responsabilités de l\'Utilisateur',
              'En utilisant cette application, vous vous engagez à :\n\n'
                  '• Fournir des informations exactes lors de l\'inscription\n'
                  '• Ne pas enregistrer de contenu offensant, diffamatoire ou illégal\n'
                  '• Respecter les consignes d\'enregistrement fournies\n'
                  '• Ne pas tenter de contourner les mesures de sécurité\n'
                  '• Signaler tout dysfonctionnement ou problème de sécurité',
            ),

            _buildSection(
              '8. Propriété Intellectuelle',
              'Les textes fournis pour l\'enregistrement peuvent être soumis à des droits d\'auteur. En participant, vous confirmez avoir le droit d\'enregistrer ces textes. Les modèles développés à partir des données collectées seront mis à disposition de la communauté scientifique sénégalaise.',
            ),

            _buildSection(
              '9. Durée de Conservation',
              'Conformément au principe de minimisation des données :\n\n'
                  '• Les données personnelles sont conservées pendant la durée nécessaire aux finalités pour lesquelles elles sont collectées\n'
                  '• Les enregistrements vocaux anonymisés peuvent être conservés pour la recherche\n'
                  '• Vous pouvez demander la suppression de vos données à tout moment',
            ),

            _buildSection(
              '10. Contact et Réclamations',
              'Pour toute question relative à ces conditions ou à vos données personnelles, vous pouvez nous contacter :\n\n'
                  'Email : contact@xelkoom.sn\n'
                  'Adresse : [Adresse au Sénégal]\n\n'
                  'Vous pouvez également saisir la Commission des Données Personnelles (CDP) du Sénégal en cas de litige.',
            ),

            _buildSection(
              '11. Modifications',
              'Ces conditions peuvent être modifiées pour se conformer à l\'évolution de la législation sénégalaise. Toute modification vous sera notifiée via l\'application.',
            ),

            _buildSection(
              '12. Droit Applicable',
              'Ces conditions sont régies par le droit sénégalais, notamment le Code Numérique du Sénégal et la loi sur la protection des données personnelles.',
            ),

            const SizedBox(height: 32),

            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: Color(0xFF1E88E5),
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Engagement de Xelkoom',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nous nous engageons à promouvoir la diversité linguistique du Sénégal et de l\'Afrique à travers le développement de technologies inclusives, dans le respect total de vos droits et de votre vie privée.',
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
