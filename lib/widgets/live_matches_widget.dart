import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../providers.dart';
import '../models/league_models.dart';
import '../theme/app_theme.dart';
import 'team_logo.dart';

/// Widget che mostra le partite live in modo compatto
class LiveMatchesWidget extends ConsumerStatefulWidget {
  final bool showHeader;
  final int maxMatches;
  final VoidCallback? onTapViewAll;

  const LiveMatchesWidget({
    super.key,
    this.showHeader = true,
    this.maxMatches = 3,
    this.onTapViewAll,
  });

  @override
  ConsumerState<LiveMatchesWidget> createState() => _LiveMatchesWidgetState();
}

class _LiveMatchesWidgetState extends ConsumerState<LiveMatchesWidget>
    with SingleTickerProviderStateMixin {
  Timer? _refreshTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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
    final liveMatchesAsync = ref.watch(serieALiveMatchesProvider);

    return liveMatchesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (matches) {
        if (matches.isEmpty) return const SizedBox.shrink();

        final displayMatches = matches.take(widget.maxMatches).toList();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.shade700,
                Colors.red.shade500,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (widget.showHeader)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: _pulseAnimation.value),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: _pulseAnimation.value * 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'LIVE NOW',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      if (matches.length > widget.maxMatches && widget.onTapViewAll != null)
                        TextButton(
                          onPressed: widget.onTapViewAll,
                          child: const Text(
                            'Vedi tutte',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              ...displayMatches.map((match) => _buildLiveMatchRow(match)),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveMatchRow(Match match) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                TeamLogo(
                  teamName: match.homeTeam.name,
                  logoUrl: match.homeTeam.logo,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.homeTeam.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              match.displayScore,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TeamLogo(
                  teamName: match.awayTeam.name,
                  logoUrl: match.awayTeam.logo,
                  size: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget per countdown alla prossima partita
class NextMatchCountdown extends ConsumerStatefulWidget {
  const NextMatchCountdown({super.key});

  @override
  ConsumerState<NextMatchCountdown> createState() => _NextMatchCountdownState();
}

class _NextMatchCountdownState extends ConsumerState<NextMatchCountdown> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    final matchStatus = ref.read(serieAMatchStatusProvider);
    matchStatus.whenData((status) {
      if (mounted && status.timeToNextMatch != null) {
        setState(() => _timeRemaining = status.timeToNextMatch!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nextMatchAsync = ref.watch(nextSerieAMatchProvider);

    return nextMatchAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (match) {
        if (match == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              const Text(
                'PROSSIMA PARTITA',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              TeamVsTeam(
                homeTeamName: match.homeTeam.name,
                homeTeamLogo: match.homeTeam.logo,
                awayTeamName: match.awayTeam.name,
                awayTeamLogo: match.awayTeam.logo,
                logoSize: 40,
                showTeamNames: true,
                teamNameStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 16),

              _buildCountdownDisplay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountdownDisplay() {
    if (_timeRemaining == Duration.zero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_soccer, color: Colors.green, size: 16),
            SizedBox(width: 8),
            Text(
              'In corso o terminata',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (days > 0) _buildTimeUnit(days.toString(), 'G'),
        _buildTimeUnit(hours.toString().padLeft(2, '0'), 'H'),
        const Text(':', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'M'),
        const Text(':', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'S'),
      ],
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentGold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card compatta per una singola partita
class MatchCard extends StatelessWidget {
  final Match match;
  final bool showDate;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    this.showDate = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: match.isLive
                ? Colors.red.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              if (showDate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: match.isLive
                      ? Colors.red.withValues(alpha: 0.2)
                      : AppTheme.accentGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    match.isLive
                      ? match.statusText
                      : _formatDateTime(match.date),
                    style: TextStyle(
                      color: match.isLive ? Colors.red : AppTheme.accentGold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        TeamLogo(
                          teamName: match.homeTeam.name,
                          logoUrl: match.homeTeam.logo,
                          size: 36,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          match.homeTeam.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      match.isFinished || match.isLive
                        ? match.displayScore
                        : 'VS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Column(
                      children: [
                        TeamLogo(
                          teamName: match.awayTeam.name,
                          logoUrl: match.awayTeam.logo,
                          size: 36,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          match.awayTeam.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final dayNames = ['', 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    return '${dayNames[date.weekday]} ${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
