import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> content;

  const TutorialPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.content,
  });
}

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<TutorialPage> _pages = [
    TutorialPage(
      title: "Bienvenue dans Xelkoom",
      subtitle: "Votre voix pour l'IA en Wolof",
      description:
          "Participez à la création d'une intelligence artificielle qui parle Wolof. Chaque enregistrement compte !",
      icon: Icons.waving_hand,
      color: Colors.orange,
      content: [
        "• Projet de recherche en IA vocale",
        "• Préservation de la langue Wolof",
        "• Contribution à l'innovation technologique",
      ],
    ),
    TutorialPage(
      title: "Comment enregistrer",
      subtitle: "Processus simple en 5 étapes",
      description:
          "Suivez ces étapes pour créer des enregistrements de qualité :",
      icon: Icons.mic,
      color: Colors.red,
      content: [
        "1. Lisez la phrase proposée",
        "2. Appuyez sur le bouton d'enregistrement",
        "3. Parlez clairement et naturellement",
        "4. Écoutez votre enregistrement",
        "5. Validez et envoyez",
      ],
    ),
    TutorialPage(
      title: "Conseils qualité",
      subtitle: "Pour des enregistrements parfaits",
      description: "Quelques conseils pour optimiser vos enregistrements :",
      icon: Icons.tips_and_updates,
      color: Colors.green,
      content: [
        "🔇 Choisissez un endroit calme",
        "📱 Tenez le téléphone à 15-20 cm",
        "🗣️ Parlez naturellement",
        "🔊 Volume modéré, ni fort ni faible",
        "📖 Comprenez la phrase avant d'enregistrer",
      ],
    ),
    TutorialPage(
      title: "Récompenses",
      subtitle: "Gagnez des points",
      description: "Votre participation est récompensée :",
      icon: Icons.emoji_events,
      color: Colors.amber,
      content: [
        "🎤 +10 points par enregistrement validé",
        "⭐ +20 points bonus première fois",
        "🔥 +50 points pour 5 enregistrements",
        "👑 Badges spéciaux pour les top contributors",
        "📊 Classement mensuel",
      ],
    ),
    TutorialPage(
      title: "Mode hors-ligne",
      subtitle: "Enregistrez partout",
      description: "Continuez même sans connexion internet :",
      icon: Icons.wifi_off,
      color: Colors.purple,
      content: [
        "💾 Sauvegarde automatique locale",
        "📱 Phrases mises en cache",
        "🔄 Synchronisation automatique",
        "⚡ Upload quand vous êtes connecté",
      ],
    ),
    TutorialPage(
      title: "Confidentialité",
      subtitle: "Vos données protégées",
      description: "Nous respectons votre vie privée :",
      icon: Icons.privacy_tip,
      color: Colors.indigo,
      content: [
        "🔐 Chiffrement des données",
        "🎯 Usage limité à la recherche",
        "👤 Anonymisation automatique",
        "❌ Droit de suppression",
        "📋 Conformité RGPD",
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Guide d\'utilisation'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _onTutorialComplete,
            child: const Text('Ignorer', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur de progression
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Étape ${_currentPage + 1} sur ${_pages.length}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Text(
                      '${((_currentPage + 1) / _pages.length * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentPage + 1) / _pages.length,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _pages[_currentPage].color,
                  ),
                ),
              ],
            ),
          ),

          // Contenu principal
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildPage(_pages[index]);
              },
            ),
          ),

          // Boutons de navigation
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  // Bouton Précédent
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: _pages[_currentPage].color),
                        ),
                        child: const Text('Précédent'),
                      ),
                    ),

                  if (_currentPage > 0) const SizedBox(width: 12),

                  // Bouton Suivant/Terminer
                  Expanded(
                    flex: _currentPage == 0 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed:
                          _currentPage == _pages.length - 1
                              ? _onTutorialComplete
                              : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Commencer'
                            : 'Suivant',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(TutorialPage page) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Icône principale
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 40, color: page.color),
          ),

          const SizedBox(height: 20),

          // Titre
          Text(
            page.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: page.color,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Sous-titre
          Text(
            page.subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          // Contenu avec points
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: page.color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  page.content.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 8, right: 12),
                            decoration: BoxDecoration(
                              color: page.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onTutorialComplete() async {
    // Mark tutorial as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);

    // Navigate back to previous screen (settings or app)
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

// Tutorial completion checker
class TutorialService {
  static const String _tutorialKey = 'tutorial_completed';
  static const String _showcaseCompletedKey = 'showcase_completed';

  static Future<bool> isTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialKey) ?? false;
  }

  static Future<void> markTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, true);
  }

  static Future<bool> isShowcaseCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showcaseCompletedKey) ?? false;
  }

  static Future<void> markShowcaseCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showcaseCompletedKey, true);
  }

  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialKey);
    await prefs.remove(_showcaseCompletedKey);
  }
}
