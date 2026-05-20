import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centre d\'aide'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),

            _buildSection('Comment utiliser l\'application', [
              _buildStep(
                1,
                'Créer un compte',
                'Inscrivez-vous avec un nom d\'utilisateur unique et un mot de passe sécurisé.',
              ),
              _buildStep(
                2,
                'Choisir une phrase',
                'Sélectionnez une phrase en Wolof dans la liste proposée.',
              ),
              _buildStep(
                3,
                'Enregistrer',
                'Appuyez et maintenez le bouton pour enregistrer votre voix.',
              ),
              _buildStep(
                4,
                'Valider',
                'Relâchez le bouton et écoutez votre enregistrement pour valider.',
              ),
              _buildStep(
                5,
                'Envoyer',
                'L\'enregistrement est automatiquement envoyé pour modération.',
              ),
            ]),

            const SizedBox(height: 24),

            _buildSection('Conseils pour un bon enregistrement', [
              _buildTip(
                Icons.volume_up,
                'Environnement calme',
                'Enregistrez dans un endroit silencieux sans bruit de fond.',
              ),
              _buildTip(
                Icons.mic,
                'Bonne distance',
                'Tenez votre téléphone à 15-20 cm de votre bouche.',
              ),
              _buildTip(
                Icons.speed,
                'Rythme naturel',
                'Parlez à un rythme normal, ni trop vite ni trop lent.',
              ),
              _buildTip(
                Icons.record_voice_over,
                'Prononciation claire',
                'Articulez bien chaque mot en Wolof.',
              ),
              _buildTip(
                Icons.repeat,
                'Refaire si nécessaire',
                'N\'hésitez pas à refaire l\'enregistrement si vous n\'êtes pas satisfait.',
              ),
            ]),

            const SizedBox(height: 24),

            _buildSection('Système de modération', [
              _buildInfo(
                Icons.hourglass_empty,
                'En attente',
                'Votre enregistrement est en cours de révision par nos modérateurs.',
                Colors.orange,
              ),
              _buildInfo(
                Icons.check_circle,
                'Validé',
                'Félicitations ! Votre enregistrement a été accepté et contribue au projet.',
                Colors.green,
              ),
              _buildInfo(
                Icons.cancel,
                'Rejeté',
                'L\'enregistrement ne respecte pas les critères de qualité. Réessayez !',
                Colors.red,
              ),
            ]),

            const SizedBox(height: 24),

            _buildSection('Système de points et classement', [
              _buildPointSystem('1 point', 'Pour chaque enregistrement validé'),
              _buildPointSystem(
                'Bonus qualité',
                'Points supplémentaires pour une excellente qualité',
              ),
              _buildPointSystem(
                'Classement',
                'Comparez votre progression avec les autres contributeurs',
              ),
              _buildPointSystem(
                'Badges',
                'Débloquez des achievements selon vos contributions',
              ),
            ]),

            const SizedBox(height: 24),

            _buildFAQSection(),

            const SizedBox(height: 24),

            _buildContactSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 3,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.help_center, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            const Text(
              'Bienvenue dans le Centre d\'aide',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Trouvez ici toutes les informations pour utiliser Xelkoom efficacement',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E88E5),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(int number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1E88E5), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointSystem(String points, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Text(
            points,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Questions fréquentes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E88E5),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFAQItem(
                  'Pourquoi mes enregistrements sont-ils rejetés ?',
                  'Les enregistrements peuvent être rejetés pour plusieurs raisons : qualité audio insuffisante, bruit de fond, mauvaise prononciation, ou non-respect du texte à lire.',
                ),
                const Divider(),
                _buildFAQItem(
                  'Combien de temps prend la modération ?',
                  'La modération prend généralement entre 24 et 48 heures. Nos modérateurs vérifient chaque enregistrement pour assurer la qualité des données.',
                ),
                const Divider(),
                _buildFAQItem(
                  'Puis-je modifier mes informations personnelles ?',
                  'Oui, vous pouvez modifier votre nom d\'utilisateur dans la section Profil. Les autres informations peuvent être mises à jour via les paramètres.',
                ),
                const Divider(),
                _buildFAQItem(
                  'Mes données sont-elles sécurisées ?',
                  'Absolument ! Nous respectons le Code Numérique du Sénégal et les standards internationaux de protection des données. Vos enregistrements sont anonymisés.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(answer, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Besoin d\'aide supplémentaire ?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E88E5),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email, color: Color(0xFF1E88E5)),
                  title: const Text('Email de support'),
                  subtitle: const Text('support@xelkoom.sn'),
                  trailing: const Icon(Icons.copy),
                  onTap: () {
                    // TODO: Copier l'email dans le presse-papiers
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.feedback, color: Colors.green),
                  title: const Text('Feedback'),
                  subtitle: const Text('feedback@xelkoom.sn'),
                  trailing: const Icon(Icons.copy),
                  onTap: () {
                    // TODO: Copier l'email dans le presse-papiers
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.orange),
                  title: const Text('Site web'),
                  subtitle: const Text('www.xelkoom.sn'),
                  trailing: const Icon(Icons.open_in_browser),
                  onTap: () {
                    // TODO: Ouvrir le site web
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
