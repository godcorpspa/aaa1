import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers.dart';
import '../models/pick.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

class StoricoScelteScreen extends ConsumerWidget {
  const StoricoScelteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: GradientBackground(child: Center(child: Text('Non autenticato'))),
      );
    }

    final picksAsync = ref.watch(userPicksProvider(user.uid));

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text('Storico Scelte'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: picksAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (e, _) => Center(
                  child: Text('Errore: $e',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7))),
                ),
                data: (picks) {
                  if (picks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'Nessuna scelta effettuata',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatsHeader(picks),
                      const SizedBox(height: 16),
                      ...picks.map((p) => _buildPickCard(p)),
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

  Widget _buildStatsHeader(List<Pick> picks) {
    final wins = picks.winsCount;
    final losses = picks.lossesCount;
    final streak = picks.currentStreak;
    final goldEarned = picks.goldTicketsEarned;
    final goldUsed = picks.goldTicketsUsed;
    final rate = picks.successRate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.elevatedCard,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Statistiche',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _rateColor(rate).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${rate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _rateColor(rate),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBox('Scelte', '${picks.length}', Icons.list),
              _statBox('Vittorie', '$wins', Icons.check_circle,
                  color: AppTheme.successGreen),
              _statBox('Sconfitte', '$losses', Icons.cancel,
                  color: AppTheme.errorRed),
              _statBox('Streak', '$streak', Icons.local_fire_department,
                  color: AppTheme.accentGold),
            ],
          ),
          if (goldEarned > 0 || goldUsed > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars, color: AppTheme.accentGold, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Gold Ticket: $goldEarned guadagnati, $goldUsed usati',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon, {Color? color}) {
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

  Widget _buildPickCard(Pick pick) {
    final color = _pickColor(pick);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_pickIcon(pick), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pick.team,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (pick.isDoubleChoice && pick.secondTeam != null) ...[
                      Text(' + ',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5))),
                      Text(
                        pick.secondTeam!,
                        style: const TextStyle(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Giornata ${pick.giornata}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Result badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              pick.resultDescription,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _pickColor(Pick pick) {
    if (pick.usedGoldTicket) return AppTheme.accentGold;
    if (pick.isPending) return Colors.grey;
    if (pick.survived) return AppTheme.successGreen;
    return AppTheme.errorRed;
  }

  IconData _pickIcon(Pick pick) {
    if (pick.usedGoldTicket) return Icons.stars;
    if (pick.isPending) return Icons.schedule;
    if (pick.survived) return Icons.check_circle;
    return Icons.cancel;
  }

  Color _rateColor(double rate) {
    if (rate >= 70) return AppTheme.successGreen;
    if (rate >= 40) return AppTheme.warningAmber;
    return AppTheme.errorRed;
  }
}
