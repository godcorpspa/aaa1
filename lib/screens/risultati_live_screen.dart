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
  ConsumerState<RisultatiLiveScreen> createState() => _RisultatiLiveScreenState();
}

class _RisultatiLiveScreenState extends ConsumerState<RisultatiLiveScreen>
    with TickerProviderStateMixin {
  Timer? _refreshTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Auto refresh ogni 30 secondi per partite live
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(serieALiveMatchesProvider);
      ref.invalidate(recentSerieAMatchesProvider);
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
    final liveMatchesAsync = ref.watch(serieALiveMatchesProvider);
    final nextMatchdayAsync = ref.watch(nextMatchdayFixturesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'RISULTATI LIVE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.invalidate(serieALiveMatchesProvider);
              ref.invalidate(nextMatchdayFixturesProvider);
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(serieALiveMatchesProvider);
              ref.invalidate(nextMatchdayFixturesProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Header
                  Text(
                    'SERIE A TIM - RISULTATI',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Partite Live o Prossime Partite
                  _buildMatchesSection(liveMatchesAsync, nextMatchdayAsync),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchesSection(AsyncValue<List<Match>> liveMatchesAsync, AsyncValue<List<Match>> nextMatchdayAsync) {
    return liveMatchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (error, stack) => _buildErrorWidget(error),
      data: (liveMatches) {
        // Se ci sono partite live, mostra quelle
        if (liveMatches.isNotEmpty) {
          return _buildLiveMatchesSection(liveMatches);
        }
        
        // Altrimenti mostra le partite della prossima giornata
        return nextMatchdayAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (error, stack) => _buildErrorWidget(error),
          data: (nextMatches) => _buildNextMatchdaySection(nextMatches),
        );
      },
    );
  }

  Widget _buildLiveMatchesSection(List<Match> liveMatches) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade600, Colors.red.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(_pulseAnimation.value),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                const Text(
                  'PARTITE LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          
          // Partite live
          Column(
            children: liveMatches.map((match) => _buildMatchCard(match)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNextMatchdaySection(List<Match> matches) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.schedule, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'PROSSIME PARTITE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          
          // Partite
          Column(
            children: matches.map((match) => _buildMatchCard(match)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    Color resultColor;
    String resultText;
    bool shouldPulse = false;

    // Determina colore e testo in base allo stato
    if (match.isLive) {
      resultColor = Colors.red;
      resultText = match.displayScore;
      shouldPulse = true;
    } else if (match.isFinished) {
      resultColor = Colors.black;
      resultText = match.displayScore;
    } else {
      resultColor = Colors.grey;
      resultText = '-';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Squadra casa
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _buildTeamLogo(match.homeTeam.name, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    match.homeTeam.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Risultato
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: shouldPulse
                ? AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Text(
                        resultText,
                        style: TextStyle(
                          color: resultColor.withOpacity(_pulseAnimation.value),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  )
                : Text(
                    resultText,
                    style: TextStyle(
                      color: resultColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          
          // Squadra trasferta
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    match.awayTeam.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                _buildTeamLogo(match.awayTeam.name, size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.white70,
            ),
            const SizedBox(height: 16),
            const Text(
              'Errore nel caricamento',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impossibile caricare i dati',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(serieALiveMatchesProvider);
                ref.invalidate(nextMatchdayFixturesProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLogo(String teamName, {double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.accentOrange,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          teamName.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}