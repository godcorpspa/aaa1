import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/league_models.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

class ClassificaScreen extends ConsumerWidget {
  const ClassificaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(serieAStandingsProvider);

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text('Classifica Serie A'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(serieAStandingsProvider),
                ),
              ],
            ),
            Expanded(
              child: standingsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('Errore: $e',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7))),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(serieAStandingsProvider),
                        child: const Text('Riprova'),
                      ),
                    ],
                  ),
                ),
                data: (standings) => _buildTable(standings),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(List<LeagueStanding> standings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const SizedBox(
                    width: 28,
                    child: Text('#',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12))),
                const Expanded(
                    child: Text('Squadra',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12))),
                for (final col in ['G', 'V', 'N', 'S', 'PT'])
                  SizedBox(
                    width: 32,
                    child: Text(col,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Rows
          ...standings.map((s) => _buildRow(s)),
        ],
      ),
    );
  }

  Widget _buildRow(LeagueStanding standing) {
    final posColor = _positionColor(standing.position);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: posColor?.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: posColor != null
            ? Border.all(color: posColor.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: posColor?.withValues(alpha: 0.2) ??
                    Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${standing.position}',
                style: TextStyle(
                  color: posColor ?? Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.surfaceElevated,
                  child: Text(
                    standing.team.name.isNotEmpty
                        ? standing.team.name[0]
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    standing.team.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          for (final val in [
            standing.played,
            standing.wins,
            standing.draws,
            standing.losses,
            standing.points,
          ])
            SizedBox(
              width: 32,
              child: Text(
                '$val',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: val == standing.points
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color? _positionColor(int pos) {
    if (pos <= 4) return AppTheme.successGreen;
    if (pos <= 6) return AppTheme.infoBlue;
    if (pos >= 18) return AppTheme.errorRed;
    return null;
  }
}
