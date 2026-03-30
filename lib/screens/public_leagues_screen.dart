import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/league_models.dart';
import '../providers/league_providers.dart';
import '../services/league_service.dart';

class PublicLeaguesScreen extends ConsumerWidget {
  const PublicLeaguesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaguesAsync = ref.watch(publicLeaguesProvider(null));

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Leghe Pubbliche'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: leaguesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          ),
          error: (e, _) => _ErrorView(error: e, ref: ref),
          data: (leagues) {
            if (leagues.isEmpty) return const _EmptyView();
            return _LeagueList(leagues: leagues);
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// League list
// ---------------------------------------------------------------------------
class _LeagueList extends ConsumerWidget {
  const _LeagueList({required this.leagues});
  final List<LastManStandingLeague> leagues;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppTheme.primaryRed,
      onRefresh: () async {
        ref.invalidate(publicLeaguesProvider(null));
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: leagues.length,
        itemBuilder: (_, i) => _LeagueCard(league: leagues[i]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// League card
// ---------------------------------------------------------------------------
class _LeagueCard extends ConsumerWidget {
  const _LeagueCard({required this.league});
  final LastManStandingLeague league;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppTheme.elevatedCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  league.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusBadge(isFull: league.isFull),
            ],
          ),

          if (league.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              league.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Participants count
          Row(
            children: [
              Icon(Icons.people_rounded,
                  color: Colors.white.withValues(alpha: 0.5), size: 16),
              const SizedBox(width: 6),
              Text(
                '${league.currentParticipants}/${league.maxParticipants} partecipanti',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Icon(Icons.person_rounded,
                  color: Colors.white.withValues(alpha: 0.5), size: 16),
              const SizedBox(width: 6),
              Text(
                league.creatorName,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Join button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: league.isFull
                  ? null
                  : () => _join(context, ref),
              child: const Text('Entra'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
    );

    try {
      final service = ref.read(leagueServiceProvider);
      await service.joinLeague(leagueId: league.id);
      navigator.pop(); // close loader
      ref.invalidate(currentUserLeaguesProvider);
      ref.invalidate(publicLeaguesProvider(null));
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Ti sei unito alla lega con successo!')),
      );
      navigator.pop(); // back to previous screen
    } on LeagueException catch (e) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Si e\' verificato un errore imprevisto.')),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isFull});
  final bool isFull;

  @override
  Widget build(BuildContext context) {
    final color = isFull ? AppTheme.errorRed : AppTheme.successGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        isFull ? 'PIENA' : 'APERTA',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty view
// ---------------------------------------------------------------------------
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nessuna lega pubblica disponibile',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error view
// ---------------------------------------------------------------------------
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.ref});
  final Object error;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppTheme.errorRed, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Errore nel caricamento delle leghe.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.toString(),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.invalidate(publicLeaguesProvider(null)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }
}
