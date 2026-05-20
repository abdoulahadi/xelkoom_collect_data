import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/leaderboard.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(leaderboardProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(leaderboardProvider);
        },
        child: leaderboardAsync.when(
          data: (leaderboard) => _buildLeaderboard(leaderboard),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(error.toString()),
        ),
      ),
    );
  }

  Widget _buildLeaderboard(LeaderboardResponse leaderboard) {
    return Column(
      children: [
        // Current user rank card
        if (leaderboard.currentUserRank != null)
          Container(
            margin: const EdgeInsets.all(16),
            child: _buildCurrentUserRankCard(leaderboard),
          ),

        // Stats summary
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildStatsCard(leaderboard),
        ),

        const SizedBox(height: 16),

        // Leaderboard list
        Expanded(
          child:
              leaderboard.entries.isEmpty
                  ? _buildEmptyLeaderboard()
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: leaderboard.entries.length,
                    itemBuilder: (context, index) {
                      return _buildLeaderboardTile(leaderboard.entries[index]);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildCurrentUserRankCard(LeaderboardResponse leaderboard) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Votre rang',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  Text(
                    '#${leaderboard.currentUserRank} sur ${leaderboard.totalUsers}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getRankLabel(leaderboard.currentUserRank!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(LeaderboardResponse leaderboard) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Total',
              '${leaderboard.totalUsers}',
              Icons.people,
              Colors.blue,
            ),
            _buildStatItem(
              'Top 10',
              '${leaderboard.entries.take(10).length}',
              Icons.star,
              Colors.orange,
            ),
            _buildStatItem(
              'Actifs',
              '${leaderboard.entries.length}',
              Icons.trending_up,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry) {
    return Card(
      elevation: entry.isCurrentUser ? 3 : 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border:
              entry.isCurrentUser
                  ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                  : null,
        ),
        child: ListTile(
          leading: _buildRankBadge(entry.rank),
          title: Row(
            children: [
              Text(
                entry.username,
                style: TextStyle(
                  fontWeight:
                      entry.isCurrentUser ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              if (entry.isCurrentUser) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Vous',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            '${entry.validatedRecordings} enregistrements • ${(entry.totalDuration / 60).toStringAsFixed(1)} min',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: _getRankColor(entry.rank), size: 20),
              Text(
                '${entry.validatedRecordings}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getRankColor(entry.rank),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color backgroundColor;
    Color textColor;
    IconData? icon;

    switch (rank) {
      case 1:
        backgroundColor = const Color(0xFFFFD700); // Gold
        textColor = Colors.black;
        icon = Icons.emoji_events;
        break;
      case 2:
        backgroundColor = const Color(0xFFC0C0C0); // Silver
        textColor = Colors.black;
        icon = Icons.emoji_events;
        break;
      case 3:
        backgroundColor = const Color(0xFFCD7F32); // Bronze
        textColor = Colors.white;
        icon = Icons.emoji_events;
        break;
      default:
        backgroundColor = Colors.grey[300]!;
        textColor = Colors.black87;
        icon = null;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Center(
        child:
            icon != null
                ? Icon(icon, color: textColor, size: 20)
                : Text(
                  '$rank',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
      ),
    );
  }

  Widget _buildEmptyLeaderboard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.leaderboard, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Aucun classement disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Commencez à enregistrer pour apparaître dans le classement !',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 100, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(leaderboardProvider);
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey[600]!;
    }
  }

  String _getRankLabel(int rank) {
    if (rank <= 3) return 'TOP 3';
    if (rank <= 10) return 'TOP 10';
    if (rank <= 50) return 'TOP 50';
    return 'PARTICIPANT';
  }
}
