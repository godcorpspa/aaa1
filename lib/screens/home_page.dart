import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../shared_providers.dart'
    show selectedLeagueDetailsProvider, mainTabIndexProvider;
import '../models/matchday.dart';
import '../models/user_data.dart';
import '../theme/app_theme.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isDisposed = false;
  int? _autoAssignCheckedForGiornata;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed && !_isDisposed) {
      final matchdayAsync = ref.read(matchdayProvider);
      matchdayAsync.whenData((md) => _startTimer(md.deadline));
    }
  }

  void _startTimer(DateTime deadline) {
    _timer?.cancel();
    if (_isDisposed) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isDisposed) return;
      final diff = deadline.difference(DateTime.now());
      if (mounted) {
        setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
      }
    });
  }

  /// If the user is still active but missed the current matchday's deadline
  /// (pick window has closed and no pick was submitted), auto-assign the
  /// first alphabetically-available team. Runs at most once per giornata.
  void _maybeAutoAssignExpiredPick(Matchday matchday, UserData user) {
    if (_autoAssignCheckedForGiornata == matchday.giornata) return;
    if (!user.isActive) return;
    if (!DateTime.now().isAfter(matchday.deadline)) return;

    _autoAssignCheckedForGiornata = matchday.giornata;

    // Kick off asynchronously; we don't await — any errors are swallowed
    // silently because this is a best-effort recovery path.
    Future.microtask(() async {
      if (_isDisposed) return;
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null || uid.isEmpty) return;
        final allTeams =
            await ref.read(serieATeamNamesProvider.future);
        if (allTeams.isEmpty) return;
        final assigned = await ref.read(repoProvider).autoAssignPickIfMissed(
              uid: uid,
              giornata: matchday.giornata,
              allTeams: allTeams,
            );
        if (assigned != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Scelta automatica: ${assigned.team} (Giornata ${matchday.giornata})',
              ),
              backgroundColor: AppTheme.warningAmber,
            ),
          );
          ref.invalidate(userDataProvider);
        }
      } catch (_) {
        // Best-effort: stay silent on failure.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchdayAsync = ref.watch(matchdayProvider);
    final userAsync = ref.watch(userDataProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: matchdayAsync.when(
          loading: () => _loading(),
          error: (e, _) => _error(e),
          data: (matchday) {
            if (_remaining == Duration.zero &&
                !matchday.deadline.isBefore(DateTime.now())) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _startTimer(matchday.deadline));
            }
            return userAsync.when(
              loading: () => _loading(),
              error: (e, _) => _error(e),
              data: (user) {
                _maybeAutoAssignExpiredPick(matchday, user);
                return _buildBody(context, matchday, user);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Matchday matchday, UserData user) {
    final leagueAsync = ref.watch(selectedLeagueDetailsProvider);
    final isExpired = _remaining == Duration.zero;

    return RefreshIndicator(
      color: AppTheme.primaryRed,
      onRefresh: () async {
        ref.invalidate(matchdayProvider);
        ref.invalidate(userDataProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Welcome header
            Text(
              'Ciao, ${user.displayName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last Man Standing - Serie A',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),

            // Selected league badge
            leagueAsync.when(
              data: (league) {
                if (league == null) return const SizedBox(height: AppSpacing.md);
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          league.isPrivate ? Icons.lock_rounded : Icons.public,
                          color: AppTheme.accentGold,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            league.name,
                            style: const TextStyle(
                              color: AppTheme.accentGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(height: AppSpacing.md),
              error: (_, __) => const SizedBox(height: AppSpacing.md),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Matchday countdown card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1E2A), Color(0xFF1A1A24)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                    ),
                    child: Text(
                      'GIORNATA ${matchday.giornata}',
                      style: TextStyle(
                        color: AppTheme.primaryRed.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppTheme.errorRed.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Text(
                        'SCADUTO',
                        style: TextStyle(
                          color: AppTheme.errorRed,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    )
                  else
                    _buildCountdownRow(),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Quick stats row
            Row(
              children: [
                _statTile(
                  Icons.local_fire_department_rounded,
                  '${user.currentStreak}',
                  'Streak',
                  AppTheme.accentOrange,
                ),
                const SizedBox(width: AppSpacing.sm),
                _statTile(
                  Icons.stars_rounded,
                  '${user.goldTickets}',
                  'Gold',
                  AppTheme.accentGold,
                ),
                const SizedBox(width: AppSpacing.sm),
                _statTile(
                  Icons.sports_soccer_rounded,
                  '${user.teamsUsed.length}',
                  'Usate',
                  AppTheme.accentCyan,
                ),
                const SizedBox(width: AppSpacing.sm),
                _statTile(
                  user.isActive
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  user.isActive ? 'IN' : 'OUT',
                  'Status',
                  user.isActive ? AppTheme.successGreen : AppTheme.errorRed,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Gioca Ora button
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight,
              child: ElevatedButton(
                onPressed: user.isActive
                    ? () => ref
                        .read(mainTabIndexProvider.notifier)
                        .state = 2
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppTheme.surfaceElevated,
                  disabledForegroundColor:
                      Colors.white.withValues(alpha: 0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'GIOCA ORA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownRow() {
    final d = _remaining.inDays;
    final h = _remaining.inHours % 24;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _countdownUnit('$d', 'GG'),
        _countdownSep(),
        _countdownUnit(h.toString().padLeft(2, '0'), 'ORE'),
        _countdownSep(),
        _countdownUnit(m.toString().padLeft(2, '0'), 'MIN'),
        _countdownSep(),
        _countdownUnit(s.toString().padLeft(2, '0'), 'SEC'),
      ],
    );
  }

  Widget _countdownUnit(String value, String label) {
    return Column(
      children: [
        Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _countdownSep() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 6, right: 6),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.2),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statTile(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _loading() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primaryRed),
    );
  }

  Widget _error(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Errore: $error',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () {
                ref.invalidate(matchdayProvider);
                ref.invalidate(userDataProvider);
              },
              child: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }
}
