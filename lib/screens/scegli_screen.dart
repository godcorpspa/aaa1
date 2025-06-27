import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../providers.dart';
import '../models/league_models.dart';
import '../models/pick.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

class ScegliScreen extends ConsumerStatefulWidget {
  const ScegliScreen({super.key});

  @override
  ConsumerState<ScegliScreen> createState() => _ScegliScreenState();
}

class _ScegliScreenState extends ConsumerState<ScegliScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  Duration _timeToNext = Duration.zero;
  String? _selectedTeam;
  
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
    
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCountdownTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final matchStatus = ref.read(serieAMatchStatusProvider);
      matchStatus.whenData((status) {
        final timeToNext = status.timeToNextMatch;
        if (mounted && timeToNext != null) {
          setState(() => _timeToNext = timeToNext);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchStatusAsync = ref.watch(serieAMatchStatusProvider);
    final teamNamesAsync = ref.watch(serieATeamNamesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'SCEGLI',
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
              ref.invalidate(serieAMatchStatusProvider);
              ref.invalidate(serieATeamNamesProvider);
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: matchStatusAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, stack) => _buildErrorWidget(context, error),
            data: (matchStatus) => _buildContent(context, matchStatus, teamNamesAsync),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SerieAMatchStatus matchStatus, AsyncValue<List<String>> teamNamesAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Header
          Text(
            'SCEGLI LA TUA SQUADRA',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 30),
          
          // Partite Live (se presenti)
          if (matchStatus.hasLiveMatches) ...[
            _buildLiveMatchesSection(matchStatus.liveMatches),
            const SizedBox(height: 30),
          ],
          
          // Countdown e selezione squadra
          _buildNextMatchSection(matchStatus.nextMatch, teamNamesAsync),
          
          const SizedBox(height: 30),
          
          // Informazioni aggiuntive
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildLiveMatchesSection(List<Match> liveMatches) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade600, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
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
          const SizedBox(height: 16),
          
          ...liveMatches.map((match) => _buildLiveMatchCard(match)),
        ],
      ),
    );
  }

  Widget _buildLiveMatchCard(Match match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Squadra casa
          Expanded(
            child: Column(
              children: [
                _buildTeamLogo(match.homeTeam.name),
                const SizedBox(height: 8),
                Text(
                  match.homeTeam.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Risultato e tempo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Text(
                  match.displayScore,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match.statusText,
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
          
          // Squadra trasferta
          Expanded(
            child: Column(
              children: [
                _buildTeamLogo(match.awayTeam.name),
                const SizedBox(height: 8),
                Text(
                  match.awayTeam.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextMatchSection(Match? nextMatch, AsyncValue<List<String>> teamNamesAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.schedule,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 16),
          
          if (nextMatch != null) ...[
            const Text(
              'PROSSIMA PARTITA',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            
            // Teams
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildTeamLogo(nextMatch.homeTeam.name),
                      const SizedBox(height: 8),
                      Text(
                        nextMatch.homeTeam.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildTeamLogo(nextMatch.awayTeam.name),
                      const SizedBox(height: 8),
                      Text(
                        nextMatch.awayTeam.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Countdown
            _buildCountdown(),
            
            const SizedBox(height: 24),
          ],
          
          // Team Selection
          _buildTeamSelection(teamNamesAsync),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    if (_timeToNext.isNegative || _timeToNext == Duration.zero) {
      return const Text(
        'PARTITA INIZIATA',
        style: TextStyle(
          color: Colors.orange,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    
    final days = _timeToNext.inDays;
    final hours = _timeToNext.inHours % 24;
    final minutes = _timeToNext.inMinutes % 60;
    final seconds = _timeToNext.inSeconds % 60;
    
    return Column(
      children: [
        const Text(
          'INIZIA TRA',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCountdownItem('$days', 'giorni'),
            _buildCountdownItem('${hours.toString().padLeft(2, '0')}', 'ore'),
            _buildCountdownItem('${minutes.toString().padLeft(2, '0')}', 'min'),
            _buildCountdownItem('${seconds.toString().padLeft(2, '0')}', 'sec'),
          ],
        ),
      ],
    );
  }

  Widget _buildCountdownItem(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSelection(AsyncValue<List<String>> teamNamesAsync) {
    return Column(
      children: [
        const Divider(color: Colors.white24),
        const SizedBox(height: 16),
        
        const Text(
          'SCEGLI LA TUA SQUADRA',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        
        const SizedBox(height: 16),
        
        teamNamesAsync.when(
          loading: () => const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
          error: (error, stack) => Text(
            'Errore nel caricamento squadre',
            style: TextStyle(color: Colors.red.shade300),
          ),
          data: (teamNames) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTeam,
                hint: const Text(
                  'Seleziona una squadra',
                  style: TextStyle(color: Colors.white70),
                ),
                dropdownColor: AppTheme.primaryRed,
                style: const TextStyle(color: Colors.white),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                isExpanded: true,
                items: teamNames.map((team) => DropdownMenuItem(
                  value: team,
                  child: Row(
                    children: [
                      _buildTeamLogo(team, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          team,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                onChanged: (team) => setState(() => _selectedTeam = team),
              ),
            ),
          ),
        ),
        
        if (_selectedTeam != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmTeamSelection(),
              icon: const Icon(Icons.check),
              label: Text('Conferma: $_selectedTeam'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'INFORMAZIONI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          const Text(
            '• Scegli una squadra che pensi vincerà la prossima partita\n'
            '• Non puoi scegliere una squadra già utilizzata\n'
            '• La scelta deve essere effettuata prima dell\'inizio delle partite\n'
            '• Sbagliare la previsione significa eliminazione\n'
            '• Puoi usare i Jolly per salvarti dalle eliminazioni',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
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

  void _confirmTeamSelection() {
    if (_selectedTeam == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Scelta'),
        content: Text(
          'Hai scelto $_selectedTeam per la prossima giornata.\n\nVuoi confermare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveTeamChoice();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
  }

  void _saveTeamChoice() async {
    if (_selectedTeam == null) return;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devi essere autenticato per fare una scelta'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Recupera la giornata corrente
      final matchdayAsync = ref.read(matchdayProvider);
      await matchdayAsync.when(
        data: (matchday) async {
          // Crea la scelta
          final pick = Pick(
            giornata: matchday.giornata,
            team: _selectedTeam!,
            usedJolly: false,
          );

          // Salva tramite repository
          await ref.read(repoProvider).submitPick(user.uid, pick);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Scelta salvata: $_selectedTeam (Giornata ${matchday.giornata})'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() => _selectedTeam = null);
          }
        },
        loading: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Caricamento dati in corso...'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel salvataggio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
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
              onPressed: () => ref.invalidate(serieAMatchStatusProvider),
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
}