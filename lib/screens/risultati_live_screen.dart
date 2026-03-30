import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../providers.dart';
import '../models/league_models.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

class RisultatiLiveScreen extends ConsumerStatefulWidget {
  const RisultatiLiveScreen({super.key});

  @override
  ConsumerState<RisultatiLiveScreen> createState() =>
      _RisultatiLiveScreenState();
}

class _RisultatiLiveScreenState extends ConsumerState<RisultatiLiveScreen>
    with SingleTickerProviderStateMixin {
  Timer? _refreshTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(serieALiveMatchesProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveAsync = ref.watch(serieALiveMatchesProvider);
    final nextFixtures = ref.watch(nextMatchdayFixturesProvider);

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text('Risultati Live'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      ref.invalidate(serieALiveMatchesProvider),
                ),
              ],
            ),
            Expanded(
              child: liveAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (e, _) => Center(
                  child: Text('Errore: $e',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7))),
                ),
                data: (liveMatches) {
                  if (liveMatches.isEmpty) {
                    return _buildNoLive(nextFixtures);
                  }
                  return _buildLiveList(liveMatches);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveList(List<Match> matches) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLiveIndicator(),
        const SizedBox(height: 16),
        ...matches.map((m) => _buildLiveMatchCard(m)),
      ],
    );
  }

  Widget _buildLiveIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed
                .withValues(alpha: 0.1 + _pulseController.value * 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryRed
                  .withValues(alpha: 0.3 + _pulseController.value * 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed
                      .withValues(alpha: 0.5 + _pulseController.value * 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'PARTITE IN CORSO',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveMatchCard(Match match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Home
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.surfaceElevated,
                  child: Text(
                    match.homeTeam.name.isNotEmpty
                        ? match.homeTeam.name[0]
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  match.homeTeam.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Score
          Column(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Text(
                  match.displayScore,
                  style: TextStyle(
                    color: AppTheme.primaryRed.withValues(
                        alpha: 0.7 + _pulseController.value * 0.3),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  match.statusText,
                  style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          // Away
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.surfaceElevated,
                  child: Text(
                    match.awayTeam.name.isNotEmpty
                        ? match.awayTeam.name[0]
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  match.awayTeam.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLive(AsyncValue<List<Match>> nextFixtures) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassCard,
          child: Column(
            children: [
              Icon(Icons.sports_soccer,
                  size: 48, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              const Text(
                'Nessuna partita in corso',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aggiornamento automatico ogni 30 secondi',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Prossime Partite',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        nextFixtures.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child:
                  CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
          ),
          error: (e, _) => Text('Errore: $e',
              style:
                  TextStyle(color: Colors.white.withValues(alpha: 0.7))),
          data: (matches) {
            if (matches.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Nessuna partita in programma',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5))),
              );
            }
            return Column(
              children: matches.map((m) => _buildUpcomingCard(m)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUpcomingCard(Match match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(match.homeTeam.name,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          Container(
            width: 70,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'VS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(match.awayTeam.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
