import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/league_models.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import 'package:intl/intl.dart';

class CalendarioScreen extends ConsumerWidget {
  const CalendarioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextFixtures = ref.watch(nextMatchdayFixturesProvider);
    final recentMatches = ref.watch(recentSerieAMatchesProvider);

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text('Calendario'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionHeader(
                      'Prossima Giornata', Icons.event, AppTheme.infoBlue),
                  const SizedBox(height: 8),
                  nextFixtures.when(
                    loading: () => _loadingCard(),
                    error: (e, _) => _errorCard('$e'),
                    data: (matches) {
                      if (matches.isEmpty) return _emptyCard('Nessuna partita');
                      return Column(
                        children: matches.map((m) => _matchCard(m)).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _sectionHeader('Risultati Recenti', Icons.history,
                      AppTheme.successGreen),
                  const SizedBox(height: 8),
                  recentMatches.when(
                    loading: () => _loadingCard(),
                    error: (e, _) => _errorCard('$e'),
                    data: (matches) {
                      if (matches.isEmpty) {
                        return _emptyCard('Nessun risultato recente');
                      }
                      final sorted = [...matches]
                        ..sort((a, b) => b.date.compareTo(a.date));
                      return Column(
                        children:
                            sorted.take(10).map((m) => _matchCard(m)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _matchCard(Match match) {
    final dateStr = DateFormat('dd MMM, HH:mm', 'it').format(match.date);
    final isLive = match.isLive;
    final isFinished = match.isFinished;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: isLive
            ? Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.5))
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Home team
              Expanded(
                child: Text(
                  match.homeTeam.name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              // Score / Status
              Container(
                width: 80,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isLive
                      ? AppTheme.primaryRed.withValues(alpha: 0.2)
                      : isFinished
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isLive || isFinished ? match.displayScore : match.statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isLive ? AppTheme.primaryRed : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              // Away team
              Expanded(
                child: Text(
                  match.awayTeam.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLive) ...[
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryRed,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(match.statusText,
                    style: const TextStyle(
                        color: AppTheme.primaryRed, fontSize: 11)),
              ] else ...[
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
              if (match.venue.isNotEmpty) ...[
                Text(' - ',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11)),
                Flexible(
                  child: Text(
                    match.venue,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      ),
    );
  }

  Widget _errorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(error,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(message,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
      ),
    );
  }
}
