import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers.dart';
import '../models/matchday.dart';
import '../models/pick.dart';
import '../models/user_data.dart';
import '../services/notification_service.dart';
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
  String? _selectedSecondTeam;
  bool _isDoubleChoice = false;
  bool _useGoldTicket = false;
  bool _deadlineNotificationScheduled = false;

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
            data: (matchday) {
              // Schedule the 30-min-before-deadline reminder once per visit.
              _maybeScheduleReminder(matchday.giornata, matchday.deadline);

              return userDataAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (_, __) => _buildErrorWidget(context),
                data: (user) {
                  // Eliminated user short-circuit: show the "you're out" panel.
                  if (!user.isActive) {
                    return _buildEliminatedPanel(user);
                  }

                  return _buildActiveBody(
                    matchday: matchday,
                    user: user,
                    canPick: canPick,
                    timeRemainingAsync: timeRemainingAsync,
                    teamNamesAsync: teamNamesAsync,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _maybeScheduleReminder(int giornata, DateTime deadline) {
    if (_deadlineNotificationScheduled) return;
    _deadlineNotificationScheduled = true;
    // Fire-and-forget; failures are logged inside the service.
    NotificationService().scheduleDeadlineReminder30MinBefore(
      giornata: giornata,
      deadline: deadline,
    );
  }

  Widget _buildActiveBody({
    required Matchday matchday,
    required UserData user,
    required bool canPick,
    required AsyncValue<Duration> timeRemainingAsync,
    required AsyncValue<List<String>> teamNamesAsync,
  }) {
    return SingleChildScrollView(
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
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
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
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Le squadre già utilizzate sono bloccate.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Pick team button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: canPick
                        ? () => _openTeamPicker(
                              teamNamesAsync,
                              user,
                              matchday.availableTeams,
                              matchday.doubleChoiceAvailable,
                            )
                        : null,
                    icon: const Icon(Icons.touch_app),
                    label: Text(
                      _labelForSelection(),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                if (_selectedTeam != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _selectedTeamCard(_selectedTeam!, isPrimary: true),
                  if (_isDoubleChoice && _selectedSecondTeam != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _selectedTeamCard(_selectedSecondTeam!, isPrimary: false),
                  ],
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Gold Ticket option
          if (user.hasGoldTicket) _buildGoldTicketTile(user, canPick),

          const SizedBox(height: AppSpacing.lg),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: ElevatedButton(
              onPressed: _canSubmit(canPick)
                  ? () => _confirmTeamSelection()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.surfaceElevated,
                disabledForegroundColor: Colors.white38,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
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
                      'Le scelte per questa giornata sono chiuse. '
                      'Attendi la prossima giornata per scegliere.',
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
    );
  }

  bool _canSubmit(bool canPick) {
    if (!canPick || _selectedTeam == null) return false;
    if (_isDoubleChoice && _selectedSecondTeam == null) return false;
    return true;
  }

  String _labelForSelection() {
    if (_selectedTeam == null) return 'Seleziona una squadra';
    if (_isDoubleChoice && _selectedSecondTeam != null) {
      return '$_selectedTeam + $_selectedSecondTeam';
    }
    if (_isDoubleChoice) return '$_selectedTeam + ?';
    return _selectedTeam!;
  }

  Widget _selectedTeamCard(String team, {required bool isPrimary}) {
    final color = isPrimary ? AppTheme.primaryRed : AppTheme.accentGold;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color,
            child: Text(
              team[0].toUpperCase(),
              style: TextStyle(
                color: isPrimary ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPrimary
                      ? (_isDoubleChoice ? 'Prima squadra' : 'Squadra scelta')
                      : 'Seconda squadra',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  team,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () => setState(() {
              if (isPrimary) {
                _selectedTeam = null;
                _selectedSecondTeam = null;
                _useGoldTicket = false;
              } else {
                _selectedSecondTeam = null;
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldTicketTile(UserData user, bool canPick) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: _useGoldTicket ? AppTheme.goldGradient : null,
        color: _useGoldTicket ? null : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.4),
        ),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Icon(
              Icons.stars,
              color: _useGoldTicket ? Colors.black87 : AppTheme.accentGold,
              size: AppSizes.iconMd,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Gold Ticket',
              style: TextStyle(
                color: _useGoldTicket ? Colors.black87 : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Vittoria automatica (${user.goldTickets} disponibili)',
          style: TextStyle(
            color: _useGoldTicket ? Colors.black54 : Colors.white54,
            fontSize: 12,
          ),
        ),
        value: _useGoldTicket,
        onChanged: canPick && _selectedTeam != null
            ? (v) => setState(() => _useGoldTicket = v)
            : null,
      ),
    );
  }

  /// Full-screen panel shown to eliminated users.
  Widget _buildEliminatedPanel(UserData user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppTheme.errorRed.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sentiment_very_dissatisfied_rounded,
                  color: AppTheme.errorRed,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Sei stato eliminato',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                user.eliminatedAtRound != null
                    ? 'La tua corsa si è fermata alla giornata ${user.eliminatedAtRound}. '
                        'Non puoi più scegliere squadre per questa lega.'
                    : 'La tua corsa si è fermata. Non puoi più scegliere squadre per questa lega.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  border: Border.all(
                    color: AppTheme.errorRed.withValues(alpha: 0.35),
                  ),
                ),
                child: const Text(
                  'FUORI DALLA COMPETIZIONE',
                  style: TextStyle(
                    color: AppTheme.errorRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
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
            _buildCountdownItem(hours.toString().padLeft(2, '0'), 'ore'),
            _buildCountdownItem(minutes.toString().padLeft(2, '0'), 'min'),
            _buildCountdownItem(seconds.toString().padLeft(2, '0'), 'sec'),
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
    UserData userData,
    List<String> availableTeams,
    bool doubleChoiceAvailable,
  ) async {
    final apiTeams = teamNamesAsync.valueOrNull ?? <String>[];
    final usedTeams = userData.teamsUsed;

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
        _selectedSecondTeam = result['secondTeam'] as String?;
        _isDoubleChoice = (result['isDoubleChoice'] as bool?) ?? false;
        if (_isDoubleChoice) _useGoldTicket = false;
      });
    }
  }

  void _confirmTeamSelection() {
    if (_selectedTeam == null) return;

    final description = _useGoldTicket
        ? 'Stai usando un Gold Ticket su $_selectedTeam.'
        : _isDoubleChoice
            ? 'Doppia scelta: $_selectedTeam + $_selectedSecondTeam.\n\n'
                'Se entrambe vincono otterrai un Gold Ticket.'
            : 'Hai scelto $_selectedTeam per la prossima giornata.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma Scelta'),
        content: Text('$description\n\nVuoi confermare?'),
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
            secondTeam: _isDoubleChoice ? _selectedSecondTeam : null,
            usedGoldTicket: _useGoldTicket,
            type: _isDoubleChoice ? PickType.doubleChoice : PickType.normal,
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
              _selectedSecondTeam = null;
              _isDoubleChoice = false;
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
