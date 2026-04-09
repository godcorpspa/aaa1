import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models/league_models.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

/// Unified calendar screen.
///
/// Shows a single list of matches grouped by matchday. For each match the
/// displayed state depends on its status:
///  * not started → kickoff time only
///  * live → live score + minute (red accent, auto-refresh every 30s)
///  * finished → final score
class CalendarioScreen extends ConsumerStatefulWidget {
  const CalendarioScreen({super.key});

  @override
  ConsumerState<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends ConsumerState<CalendarioScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      ref.invalidate(allSerieAMatchesProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(allSerieAMatchesProvider);

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text('Calendario'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      ref.invalidate(allSerieAMatchesProvider),
                ),
              ],
            ),
            Expanded(
              child: matchesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Errore nel caricamento: $e',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (matches) => _buildContent(matches),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Match> matches) {
    if (matches.isEmpty) {
      return Center(
        child: Text(
          'Nessuna partita disponibile',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
    }

    // Group by matchday (fallback to -1 if unknown).
    final byMatchday = <int, List<Match>>{};
    for (final m in matches) {
      final md = m.matchday ?? -1;
      byMatchday.putIfAbsent(md, () => <Match>[]).add(m);
    }

    // Sort matchdays and decide which one to expand first.
    final sortedKeys = byMatchday.keys.toList()..sort();
    final focusKey = _pickFocusMatchday(byMatchday, sortedKeys);

    return RefreshIndicator(
      color: AppTheme.primaryRed,
      onRefresh: () async => ref.invalidate(allSerieAMatchesProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedKeys.length,
        itemBuilder: (_, i) {
          final key = sortedKeys[i];
          final list = byMatchday[key]!
            ..sort((a, b) => a.date.compareTo(b.date));
          return _MatchdaySection(
            matchday: key,
            matches: list,
            initiallyExpanded: key == focusKey,
          );
        },
      ),
    );
  }

  /// Picks the most "interesting" matchday to auto-expand on open:
  ///  1. The first matchday with any live match
  ///  2. Otherwise the first matchday with any scheduled (not-started) match
  ///  3. Otherwise the highest matchday (most recently played)
  int _pickFocusMatchday(
    Map<int, List<Match>> byMatchday,
    List<int> sortedKeys,
  ) {
    for (final k in sortedKeys) {
      if (byMatchday[k]!.any((m) => m.isLive)) return k;
    }
    for (final k in sortedKeys) {
      if (byMatchday[k]!.any((m) => !m.hasStarted)) return k;
    }
    return sortedKeys.last;
  }
}

class _MatchdaySection extends StatefulWidget {
  const _MatchdaySection({
    required this.matchday,
    required this.matches,
    required this.initiallyExpanded,
  });

  final int matchday;
  final List<Match> matches;
  final bool initiallyExpanded;

  @override
  State<_MatchdaySection> createState() => _MatchdaySectionState();
}

class _MatchdaySectionState extends State<_MatchdaySection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final liveCount = widget.matches.where((m) => m.isLive).length;
    final label = widget.matchday > 0
        ? 'Giornata ${widget.matchday}'
        : 'Altre partite';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month_rounded,
                        color: AppTheme.accentCyan, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (liveCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$liveCount LIVE',
                            style: const TextStyle(
                              color: AppTheme.primaryRed,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0x22FFFFFF)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                children: widget.matches
                    .map((m) => _MatchRow(match: m))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final isLive = match.isLive;
    final isFinished = match.isFinished;
    final dateStr = DateFormat('dd MMM, HH:mm').format(match.date);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isLive
            ? AppTheme.primaryRed.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: isLive
            ? Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  match.homeTeam.name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                width: 74,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isLive
                      ? AppTheme.primaryRed.withValues(alpha: 0.18)
                      : isFinished
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (isLive || isFinished)
                      ? match.displayScore
                      : DateFormat('HH:mm').format(match.date),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isLive ? AppTheme.primaryRed : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  match.awayTeam.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLive) ...[
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryRed,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  match.statusText,
                  style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else if (isFinished) ...[
                Text(
                  'Finale',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
