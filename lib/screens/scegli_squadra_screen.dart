import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers.dart';
import '../models/pick.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/team_picker_dialog.dart';

class ScegliSquadraScreen extends ConsumerStatefulWidget {
  const ScegliSquadraScreen({super.key});

  @override
  ConsumerState<ScegliSquadraScreen> createState() =>
      _ScegliSquadraScreenState();
}

class _ScegliSquadraScreenState extends ConsumerState<ScegliSquadraScreen> {
  String? _selectedTeam;
  bool _useGoldTicket = false;

  // Fallback list: Serie A 2024-25 teams (used when API fails/loading)
  static const List<String> _fallbackSerieATeams = [
    'AC Milan',
    'Atalanta',
    'Bologna',
    'Cagliari',
    'Como',
    'Empoli',
    'Fiorentina',
    'Genoa',
    'Hellas Verona',
    'Inter',
    'Juventus',
    'Lazio',
    'Lecce',
    'Monza',
    'Napoli',
    'Parma',
    'Roma',
    'Torino',
    'Udinese',
    'Venezia',
  ];

  @override
  Widget build(BuildContext context) {
    final matchdayAsync = ref.watch(matchdayProvider);
    final userDataAsync = ref.watch(userDataProvider);
    final canPick = ref.watch(canMakePickProvider);
    final timeRemainingAsync = ref.watch(timeRemainingProvider);
    final teamNamesAsync = ref.watch(serieATeamNamesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'SCEGLI SQUADRA',
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
              ref.invalidate(matchdayProvider);
              ref.invalidate(serieATeamNamesProvider);
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: matchdayAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, _) => _buildErrorWidget(context),
            data: (matchday) => SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // Matchday info & countdown
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: AppTheme.elevatedCard,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppTheme.dangerGradient,
                            borderRadius:
                                BorderRadius.circular(AppRadius.xxl),
                          ),
                          child: Text(
                            'GIORNATA ${matchday.giornata}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          matchday.statusDescription,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Countdown
                        timeRemainingAsync.when(
                          data: (duration) => _buildCountdown(duration),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Team selection section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: AppTheme.elevatedCard,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.sports_soccer,
                          color: Colors.white,
                          size: AppSizes.iconLg,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'SCEGLI LA TUA SQUADRA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Pick team button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: canPick
                                ? () => _openTeamPicker(
                                      teamNamesAsync,
                                      userDataAsync,
                                      matchday.availableTeams,
                                      matchday.doubleChoiceAvailable,
                                    )
                                : null,
                            icon: const Icon(Icons.touch_app),
                            label: Text(
                              _selectedTeam ?? 'Seleziona una squadra',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _selectedTeam != null
                                  ? AppTheme.accentGold
                                  : Colors.white,
                              side: BorderSide(
                                color: _selectedTeam != null
                                    ? AppTheme.accentGold
                                    : Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),

                        // Currently selected team
                        if (_selectedTeam != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed
                                  .withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: AppTheme.primaryRed
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.primaryRed,
                                  child: Text(
                                    _selectedTeam![0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Squadra selezionata',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedTeam!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white54,
                                  ),
                                  onPressed: () => setState(() {
                                    _selectedTeam = null;
                                    _useGoldTicket = false;
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Gold Ticket option
                  userDataAsync.when(
                    data: (userData) {
                      if (!userData.hasGoldTicket) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          gradient: _useGoldTicket
                              ? AppTheme.goldGradient
                              : null,
                          color: _useGoldTicket
                              ? null
                              : AppTheme.surfaceCard,
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: AppTheme.accentGold
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              Icon(
                                Icons.stars,
                                color: _useGoldTicket
                                    ? Colors.black87
                                    : AppTheme.accentGold,
                                size: AppSizes.iconMd,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Gold Ticket',
                                style: TextStyle(
                                  color: _useGoldTicket
                                      ? Colors.black87
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Vittoria automatica (${userData.goldTickets} disponibili)',
                            style: TextStyle(
                              color: _useGoldTicket
                                  ? Colors.black54
                                  : Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          value: _useGoldTicket,
                          onChanged: canPick && _selectedTeam != null
                              ? (v) => setState(
                                  () => _useGoldTicket = v)
                              : null,
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.buttonHeight,
                    child: ElevatedButton(
                      onPressed:
                          canPick && _selectedTeam != null
                              ? () => _confirmTeamSelection()
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppTheme.surfaceElevated,
                        disabledForegroundColor: Colors.white38,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: const Text(
                        'CONFERMA SCELTA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                  if (!canPick) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: AppTheme.statusCard(StatusType.warning),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_clock,
                            color: AppTheme.warningAmber,
                            size: AppSizes.iconSm,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Le scelte per questa giornata sono chiuse',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdown(Duration duration) {
    if (duration == Duration.zero) {
      return const Text(
        'SCELTE CHIUSE',
        style: TextStyle(
          color: AppTheme.warningAmber,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    return Column(
      children: [
        Text(
          'TEMPO RIMANENTE',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCountdownItem('$days', 'giorni'),
            _buildCountdownItem(
                hours.toString().padLeft(2, '0'), 'ore'),
            _buildCountdownItem(
                minutes.toString().padLeft(2, '0'), 'min'),
            _buildCountdownItem(
                seconds.toString().padLeft(2, '0'), 'sec'),
          ],
        ),
      ],
    );
  }

  Widget _buildCountdownItem(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed,
            borderRadius: BorderRadius.circular(AppRadius.sm),
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
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _openTeamPicker(
    AsyncValue<List<String>> teamNamesAsync,
    AsyncValue<dynamic> userDataAsync,
    List<String> availableTeams,
    bool doubleChoiceAvailable,
  ) async {
    final apiTeams = teamNamesAsync.valueOrNull ?? <String>[];
    final usedTeams = userDataAsync.whenData<List<String>>(
      (ud) => ud.teamsUsed,
    ).valueOrNull ?? <String>[];

    // Priority order:
    // 1. Teams restricted by matchday config (if set)
    // 2. Teams loaded from API
    // 3. Hardcoded Serie A fallback (never empty)
    List<String> teamsToShow;
    if (availableTeams.isNotEmpty) {
      teamsToShow = availableTeams;
    } else if (apiTeams.isNotEmpty) {
      teamsToShow = apiTeams;
    } else {
      teamsToShow = _fallbackSerieATeams;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => TeamPickerDialog(
        availableTeams: teamsToShow,
        usedTeams: usedTeams,
        initialSelection: _selectedTeam,
        allowDoubleChoice: doubleChoiceAvailable,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedTeam = result['team'] as String?;
      });
    }
  }

  void _confirmTeamSelection() {
    if (_selectedTeam == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma Scelta'),
        content: Text(
          _useGoldTicket
              ? 'Stai usando un Gold Ticket su $_selectedTeam.\n\nVuoi confermare?'
              : 'Hai scelto $_selectedTeam per la prossima giornata.\n\nVuoi confermare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveTeamChoice();
            },
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Devi essere autenticato per fare una scelta'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
        return;
      }

      final matchdayAsync = ref.read(matchdayProvider);
      await matchdayAsync.when(
        data: (matchday) async {
          final pick = Pick(
            giornata: matchday.giornata,
            team: _selectedTeam!,
            usedGoldTicket: _useGoldTicket,
          );

          await ref.read(repoProvider).submitPick(user.uid, pick);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Scelta salvata: $_selectedTeam (Giornata ${matchday.giornata})',
                ),
                backgroundColor: AppTheme.successGreen,
              ),
            );
            setState(() {
              _selectedTeam = null;
              _useGoldTicket = false;
            });
          }
        },
        loading: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Caricamento dati in corso...'),
              backgroundColor: AppTheme.warningAmber,
            ),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore: $error'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel salvataggio: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppTheme.glassCard,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: AppSizes.iconXl,
              color: Colors.white70,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Errore nel caricamento',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Impossibile caricare i dati',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(matchdayProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }
}
