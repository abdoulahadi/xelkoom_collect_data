import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../models/recording.dart';
import 'recording_screen.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';
import 'recordings_history_screen.dart';
import '../settings/settings_screen.dart';

// Provider pour contrôler le rafraîchissement
final dashboardRefreshProvider = StateProvider<int>((ref) => 0);
final leaderboardRefreshProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<_DashboardTabState> _dashboardKey =
      GlobalKey<_DashboardTabState>();

  void _navigateToTab(int index) {
    final previousIndex = _currentIndex;
    setState(() {
      _currentIndex = index;
    });

    // Si on navigue vers le Dashboard (index 0) depuis un autre onglet, rafraîchir les données
    if (index == 0 && previousIndex != 0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _dashboardKey.currentState?.refreshData();
      });
    }

    // Si on navigue vers le Leaderboard (index 2) depuis un autre onglet, rafraîchir les données
    if (index == 2 && previousIndex != 2) {
      Future.delayed(const Duration(milliseconds: 100), () {
        ref.invalidate(leaderboardProvider);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardTab(key: _dashboardKey, onNavigateToTab: _navigateToTab),
          const RecordingScreen(),
          const LeaderboardScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          final previousIndex = _currentIndex;
          setState(() => _currentIndex = index);

          // Si on navigue vers le Dashboard (index 0) depuis un autre onglet, rafraîchir les données
          if (index == 0 && previousIndex != 0) {
            Future.delayed(const Duration(milliseconds: 100), () {
              _dashboardKey.currentState?.refreshData();
            });
          }

          // Si on navigue vers le Leaderboard (index 2) depuis un autre onglet, rafraîchir les données
          if (index == 2 && previousIndex != 2) {
            Future.delayed(const Duration(milliseconds: 100), () {
              ref.invalidate(leaderboardProvider);
            });
          }
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Enregistrer'),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Classement',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class DashboardTab extends ConsumerStatefulWidget {
  final Function(int)? onNavigateToTab;

  const DashboardTab({super.key, this.onNavigateToTab});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    // Rafraîchir les données lors du chargement avec un petit délai
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _refreshData();
      }
    });
  }

  Future<void> _refreshData() async {
    print('DashboardTab: Refreshing data...');

    // Vérifier si l'utilisateur est authentifié avant de rafraîchir
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      print('DashboardTab: User not authenticated, skipping refresh');
      return;
    }

    // Mettre à jour le provider de rafraîchissement pour déclencher la reconstruction
    ref.read(dashboardRefreshProvider.notifier).state++;

    // Invalider les providers pour forcer le rechargement
    ref.invalidate(userStatsProvider);
    ref.invalidate(recentRecordingsProvider);

    print('DashboardTab: Providers invalidated');

    if (_isInitialLoad && mounted) {
      setState(() {
        _isInitialLoad = false;
      });
    }
  }

  // Méthode publique pour permettre le rafraîchissement depuis l'extérieur
  void refreshData() {
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userStatsAsync = ref.watch(userStatsProvider);
    // Observer le provider de rafraîchissement pour déclencher la reconstruction
    ref.watch(dashboardRefreshProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xelkoom'),
        elevation: 0,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.notifications_outlined),
          //   onPressed: () {
          //     // TODO: Implement notifications
          //   },
          // ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              _buildWelcomeCard(authState.user),
              const SizedBox(height: 20),

              // Stats section
              userStatsAsync.when(
                data: (stats) => _buildStatsSection(stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorCard(error.toString()),
              ),
              const SizedBox(height: 20),

              // Quick actions
              _buildQuickActions(context),
              const SizedBox(height: 20),

              // Recent activity
              _buildRecentActivity(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(User? user) {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour ${user?.username ?? 'Utilisateur'}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Prêt à contribuer à l\'avenir de la technologie vocale en Wolof?',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(UserStats? stats) {
    if (stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vos statistiques',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Enregistrements',
                stats.totalRecordings.toString(),
                Icons.mic,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Points',
                stats.validatedRecordings.toString(),
                Icons.star,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Temps total',
                '${(stats.totalDuration / 60).toStringAsFixed(1)} min',
                Icons.timer,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Rang',
                '#${stats.validatedRecordings + 1}',
                Icons.emoji_events,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.mic, color: Colors.red),
            title: const Text('Commencer un enregistrement'),
            subtitle: const Text('Enregistrez une nouvelle phrase'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to recording tab
              if (widget.onNavigateToTab != null) {
                widget.onNavigateToTab!(1); // Index 1 = Recording tab
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.history, color: Colors.blue),
            title: const Text('Mes enregistrements'),
            subtitle: const Text('Voir vos contributions'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RecordingsHistoryScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
    final recentRecordingsAsync = ref.watch(recentRecordingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activité récente',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        recentRecordingsAsync.when(
          data:
              (recordings) =>
                  recordings.isEmpty
                      ? _buildEmptyActivity()
                      : _buildActivityList(context, recordings),
          loading: () => _buildActivityLoading(),
          error: (error, stack) => _buildActivityError(error.toString()),
        ),
      ],
    );
  }

  Widget _buildEmptyActivity() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.history, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Aucune activité récente',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Commencez à enregistrer pour voir votre activité ici.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(BuildContext context, List<Recording> recordings) {
    return Card(
      elevation: 1,
      child: Column(
        children: [
          ...recordings
              .take(3)
              .map((recording) => _buildActivityTile(recording)),
          if (recordings.length > 3)
            ListTile(
              leading: const Icon(Icons.more_horiz, color: Colors.blue),
              title: const Text('Voir tous les enregistrements'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RecordingsHistoryScreen(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(Recording recording) {
    return ListTile(
      leading: _buildRecordingStatusIcon(recording.status),
      title: Text('Enregistrement #${recording.id}'),
      subtitle: Text(_formatActivityDate(recording.createdAt)),
      trailing: _buildRecordingStatusChip(recording.status),
    );
  }

  Widget _buildRecordingStatusIcon(RecordingStatus status) {
    switch (status) {
      case RecordingStatus.pending:
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      case RecordingStatus.validated:
        return const Icon(Icons.check_circle, color: Colors.green);
      case RecordingStatus.rejected:
        return const Icon(Icons.cancel, color: Colors.red);
    }
  }

  Widget _buildRecordingStatusChip(RecordingStatus status) {
    Color color;
    String label;

    switch (status) {
      case RecordingStatus.pending:
        color = Colors.orange;
        label = 'En attente';
        break;
      case RecordingStatus.validated:
        color = Colors.green;
        label = 'Validé';
        break;
      case RecordingStatus.rejected:
        color = Colors.red;
        label = 'Rejeté';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  String _formatActivityDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildActivityLoading() {
    return const Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildActivityError(String error) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
