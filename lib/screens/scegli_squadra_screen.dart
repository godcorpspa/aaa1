import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../providers.dart';
import '../models/league_models.dart';
import '../models/pick.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/team_logo.dart';
import '../services/notification_service.dart';

class ScegliScreen extends ConsumerStatefulWidget {
  const ScegliScreen({super.key});

  @override
  ConsumerState<ScegliScreen> createState() => _ScegliScreenState();
}

class _ScegliScreenState extends ConsumerState<ScegliScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  Duration _timeToNext = Duration.zero;
  Team? _selectedTeam; // Ora salviamo l'intero oggetto Team
  
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
    final teamsAsync = ref.watch(serieATeamsProvider); // Usa il provider che ritorna Team completi

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
              ref.invalidate(serieATeamsProvider);
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
            data: (matchStatus) => _buildContent(context, matchStatus, teamsAsync),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SerieAMatchStatus matchStatus, AsyncValue<List<Team>> teamsAsync) {
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
          _buildNextMatchSection(matchStatus.nextMatch, teamsAsync),
          
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
          // Squadra casa con logo
          Expanded(
            child: Column(
              children: [
                TeamLogo(
                  teamName: match.homeTeam.name,
                  logoUrl: match.homeTeam.logo,
                  size: 40,
                ),
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
          
          // Squadra trasferta con logo
          Expanded(
            child: Column(
              children: [
                TeamLogo(
                  teamName: match.awayTeam.name,
                  logoUrl: match.awayTeam.logo,
                  size: 40,
                ),
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

  Widget _buildNextMatchSection(Match? nextMatch, AsyncValue<List<Team>> teamsAsync) {
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
            
            // Teams con loghi reali
            TeamVsTeam(
              homeTeamName: nextMatch.homeTeam.name,
              homeTeamLogo: nextMatch.homeTeam.logo,
              awayTeamName: nextMatch.awayTeam.name,
              awayTeamLogo: nextMatch.awayTeam.logo,
              logoSize: 48,
              teamNameStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Countdown
            _buildCountdown(),
            
            const SizedBox(height: 24),
          ],
          
          // Team Selection con loghi
          _buildTeamSelection(teamsAsync),
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

  Widget _buildTeamSelection(AsyncValue<List<Team>> teamsAsync) {
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
        
        teamsAsync.when(
          loading: () => const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
          error: (error, stack) => Text(
            'Errore nel caricamento squadre',
            style: TextStyle(color: Colors.red.shade300),
          ),
          data: (teams) => Column(
            children: [
              // Pulsante per aprire il selettore squadre
              InkWell(
                onTap: () => _showTeamPickerDialog(context, teams),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedTeam != null 
                          ? AppTheme.accentOrange 
                          : Colors.white.withOpacity(0.3),
                      width: _selectedTeam != null ? 2 : 1,
                    ),
                  ),
                  child: _selectedTeam != null
                      ? Row(
                          children: [
                            TeamLogo(
                              teamName: _selectedTeam!.name,
                              logoUrl: _selectedTeam!.logo,
                              size: 40,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Squadra selezionata',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _selectedTeam!.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.edit, color: Colors.white70),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_soccer, color: Colors.white.withOpacity(0.7)),
                            const SizedBox(width: 12),
                            Text(
                              'Tocca per selezionare una squadra',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
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
                    label: Text('Conferma: ${_selectedTeam!.name}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showTeamPickerDialog(BuildContext context, List<Team> teams) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TeamPickerBottomSheet(
        teams: teams,
        selectedTeam: _selectedTeam,
        onTeamSelected: (team) {
          setState(() => _selectedTeam = team);
          Navigator.pop(context);
        },
      ),
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

  void _confirmTeamSelection() {
    if (_selectedTeam == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Conferma Scelta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TeamLogo(
              teamName: _selectedTeam!.name,
              logoUrl: _selectedTeam!.logo,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'Hai scelto ${_selectedTeam!.name} per la prossima giornata.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vuoi confermare?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveTeamChoice();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
            ),
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
            team: _selectedTeam!.name,
            usedJolly: false,
          );

          // Salva tramite repository
          await ref.read(repoProvider).submitPick(user.uid, pick);

          // Iscrivi alle notifiche per questa squadra
          try {
            await NotificationService().subscribeToTeam(_selectedTeam!.name);
          } catch (e) {
            print('Errore iscrizione notifiche: $e');
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    TeamLogo(
                      teamName: _selectedTeam!.name,
                      logoUrl: _selectedTeam!.logo,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('✅ Scelta salvata: ${_selectedTeam!.name} (Giornata ${matchday.giornata})'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
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

/// Bottom sheet per selezionare la squadra con loghi
class _TeamPickerBottomSheet extends StatefulWidget {
  final List<Team> teams;
  final Team? selectedTeam;
  final Function(Team) onTeamSelected;

  const _TeamPickerBottomSheet({
    required this.teams,
    this.selectedTeam,
    required this.onTeamSelected,
  });

  @override
  State<_TeamPickerBottomSheet> createState() => _TeamPickerBottomSheetState();
}

class _TeamPickerBottomSheetState extends State<_TeamPickerBottomSheet> {
  String _searchQuery = '';
  
  List<Team> get _filteredTeams {
    if (_searchQuery.isEmpty) return widget.teams;
    return widget.teams
        .where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Seleziona Squadra',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Search bar
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Cerca squadra...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista squadre
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredTeams.length,
              itemBuilder: (context, index) {
                final team = _filteredTeams[index];
                final isSelected = widget.selectedTeam?.id == team.id;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onTeamSelected(team),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.accentOrange.withOpacity(0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? AppTheme.accentOrange 
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            TeamLogo(
                              teamName: team.name,
                              logoUrl: team.logo,
                              size: 48,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                team.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppTheme.accentOrange : Colors.black87,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentOrange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}