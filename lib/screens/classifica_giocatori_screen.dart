import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../services/firestore_repo.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

class ClassificaGiocatoriScreen extends ConsumerWidget {
  const ClassificaGiocatoriScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text('Classifica Giocatori'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<UserRanking>>(
                future: ref.read(repoProvider).getLeaderboard(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Errore nel caricamento',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    );
                  }

                  final players = snapshot.data ?? [];
                  if (players.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.leaderboard,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('Nessun giocatore',
                              style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.6))),
                        ],
                      ),
                    );
                  }

                  final active = players.where((p) => p.isActive).length;
                  final eliminated = players.length - active;

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStats(players.length, active, eliminated),
                      const SizedBox(height: 16),
                      if (players.length >= 3) ...[
                        _buildPodium(players.take(3).toList()),
                        const SizedBox(height: 16),
                      ],
                      ...List.generate(players.length, (i) {
                        return _buildPlayerRow(players[i], i + 1);
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(int total, int active, int eliminated) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.elevatedCard,
      child: Row(
        children: [
          _statItem('Totale', '$total', Icons.people),
          _statItem('Attivi', '$active', Icons.check_circle,
              color: AppTheme.successGreen),
          _statItem('Eliminati', '$eliminated', Icons.cancel,
              color: AppTheme.errorRed),
          _statItem(
            'Tasso',
            total > 0
                ? '${((active / total) * 100).toStringAsFixed(0)}%'
                : '0%',
            Icons.trending_up,
            color: AppTheme.infoBlue,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.white54),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPodium(List<UserRanking> top3) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.elevatedCard,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top3.length > 1) _podiumItem(top3[1], 2, 70),
          _podiumItem(top3[0], 1, 90),
          if (top3.length > 2) _podiumItem(top3[2], 3, 55),
        ],
      ),
    );
  }

  Widget _podiumItem(UserRanking player, int position, double height) {
    final colors = [AppTheme.accentGold, Colors.grey, const Color(0xFFCD7F32)];
    final icons = [Icons.looks_one, Icons.looks_two, Icons.looks_3];
    final color = colors[position - 1];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: position == 1 ? 28 : 22,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(
            player.displayName.isNotEmpty ? player.displayName[0] : '?',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: position == 1 ? 20 : 16,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          player.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${player.currentStreak} streak',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 50,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Icon(icons[position - 1], color: color, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRow(UserRanking player, int position) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: player.isActive
            ? AppTheme.surfaceCard
            : AppTheme.surfaceCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: position <= 3
            ? Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$position',
              style: TextStyle(
                color: position <= 3 ? AppTheme.accentGold : Colors.white54,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.surfaceElevated,
            child: Text(
              player.displayName.isNotEmpty ? player.displayName[0] : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  style: TextStyle(
                    color: player.isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${player.currentStreak} streak',
                style: const TextStyle(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                '${player.totalSurvivals} vittorie',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: player.isActive
                  ? AppTheme.successGreen.withValues(alpha: 0.15)
                  : AppTheme.errorRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              player.isActive ? 'Attivo' : 'Out',
              style: TextStyle(
                color: player.isActive
                    ? AppTheme.successGreen
                    : AppTheme.errorRed,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
