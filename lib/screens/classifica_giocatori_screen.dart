import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/league_models.dart';
import '../providers/league_providers.dart';
import '../shared_providers.dart' show selectedLeagueProvider;
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

/// Screen that lists ALL players of the currently selected league.
///
/// This is NOT a ranking: active and eliminated players are both shown.
/// Eliminated players are visually dimmed and tagged with a red badge
/// plus an icon, as requested by the product spec.
class ClassificaGiocatoriScreen extends ConsumerWidget {
  const ClassificaGiocatoriScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagueId = ref.watch(selectedLeagueProvider);

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text('Giocatori Lega'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: leagueId == null
                  ? _buildNoLeague()
                  : _buildParticipants(ref, leagueId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLeague() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined,
                size: 64, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'Nessuna lega selezionata',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Entra o crea una lega per vedere i giocatori',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipants(WidgetRef ref, String leagueId) {
    final participantsAsync =
        ref.watch(leagueParticipantsProvider(leagueId));

    return participantsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Errore nel caricamento: $e',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (participants) {
        if (participants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_off,
                    size: 64, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  'Nessun giocatore nella lega',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6)),
                ),
              ],
            ),
          );
        }

        final active =
            participants.where((p) => p.isActive).toList(growable: false);
        final eliminated =
            participants.where((p) => !p.isActive).toList(growable: false);

        // Active first (sorted by streak desc), then eliminated (by round desc).
        final sortedActive = [...active]
          ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
        final sortedEliminated = [...eliminated]
          ..sort((a, b) {
            final ar = a.eliminatedAtRound ?? 0;
            final br = b.eliminatedAtRound ?? 0;
            return br.compareTo(ar);
          });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStats(participants.length, active.length, eliminated.length),
            const SizedBox(height: 16),
            if (sortedActive.isNotEmpty) ...[
              _sectionLabel(
                'Ancora in corsa (${sortedActive.length})',
                Icons.check_circle_rounded,
                AppTheme.successGreen,
              ),
              const SizedBox(height: 8),
              ...sortedActive.map(_buildPlayerRow),
              const SizedBox(height: 20),
            ],
            if (sortedEliminated.isNotEmpty) ...[
              _sectionLabel(
                'Eliminati (${sortedEliminated.length})',
                Icons.cancel_rounded,
                AppTheme.errorRed,
              ),
              const SizedBox(height: 8),
              ...sortedEliminated.map(_buildPlayerRow),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String text, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(int total, int active, int eliminated) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _statItem('Totale', '$total', Icons.people),
          _statItem('In corsa', '$active', Icons.check_circle,
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(LeagueParticipant player) {
    final isOut = !player.isActive;
    final nameColor =
        isOut ? Colors.white.withValues(alpha: 0.45) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isOut
            ? AppTheme.surfaceCard.withValues(alpha: 0.5)
            : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOut
              ? AppTheme.errorRed.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isOut
                    ? AppTheme.surfaceElevated.withValues(alpha: 0.5)
                    : AppTheme.surfaceElevated,
                child: Text(
                  player.displayName.isNotEmpty
                      ? player.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: isOut
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isOut)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.errorRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName.isNotEmpty
                      ? player.displayName
                      : 'Sconosciuto',
                  style: TextStyle(
                    color: nameColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    decoration: isOut ? TextDecoration.lineThrough : null,
                    decorationColor:
                        Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 2),
                if (isOut)
                  Text(
                    player.eliminatedAtRound != null
                        ? 'Eliminato alla giornata ${player.eliminatedAtRound}'
                        : 'Eliminato',
                    style: TextStyle(
                      color: AppTheme.errorRed.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    'Streak ${player.currentStreak} · ${player.totalSurvivals} vinte',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isOut
                  ? AppTheme.errorRed.withValues(alpha: 0.15)
                  : AppTheme.successGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isOut
                    ? AppTheme.errorRed.withValues(alpha: 0.35)
                    : AppTheme.successGreen.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOut ? Icons.cancel_rounded : Icons.check_circle_rounded,
                  size: 12,
                  color: isOut ? AppTheme.errorRed : AppTheme.successGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  isOut ? 'OUT' : 'IN',
                  style: TextStyle(
                    color: isOut ? AppTheme.errorRed : AppTheme.successGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
