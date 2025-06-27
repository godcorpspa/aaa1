import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/league_models.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

class CalendarioScreen extends ConsumerWidget {
  const CalendarioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextMatchdayAsync = ref.watch(nextMatchdayFixturesProvider);
    final recentMatchesAsync = ref.watch(recentSerieAMatchesProvider);

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
          'CALENDARIO',
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
              ref.invalidate(nextMatchdayFixturesProvider);
              ref.invalidate(recentSerieAMatchesProvider);
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(nextMatchdayFixturesProvider);
              ref.invalidate(recentSerieAMatchesProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Header
                  Text(
                    'SERIE A TIM - CALENDARIO',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Prossima Giornata
                  _buildNextMatchdaySection(context, nextMatchdayAsync),
                  
                  const SizedBox(height: 30),
                  
                  // Risultati Recenti
                  _buildRecentMatchesSection(context, recentMatchesAsync),
                  
                  const SizedBox(height: 30),
                  
                  // Informazioni Calendario
                  _buildCalendarInfo(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextMatchdaySection(BuildContext context, AsyncValue<List<Match>> nextMatchdayAsync) {
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
                  'PROSSIMA GIORNATA',
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
          
          // Content
          nextMatchdayAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, stack) => _buildErrorSection('Errore nel caricamento prossime partite'),
            data: (matches) => matches.isEmpty
                ? _buildEmptySection('Nessuna partita programmata')
                : Column(
                    children: matches.map((match) => _buildNextMatchCard(match)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextMatchCard(Match match) {
    final dateFormat = '${_getDayName(match.date.weekday)} ${match.date.day}/${match.date.month}';
    final timeFormat = '${match.date.hour.toString().padLeft(2, '0')}:${match.date.minute.toString().padLeft(2, '0')}';
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Data e ora
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$dateFormat - $timeFormat',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Teams
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(match.homeTeam.name, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      match.homeTeam.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(match.awayTeam.name, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      match.awayTeam.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Stadio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stadium, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text(
                  match.venue,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMatchesSection(BuildContext context, AsyncValue<List<Match>> recentMatchesAsync) {
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
                colors: [Colors.green.shade600, Colors.green.shade400],
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
                Icon(Icons.history, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'RISULTATI RECENTI',
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
          
          // Content
          recentMatchesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, stack) => _buildErrorSection('Errore nel caricamento risultati'),
            data: (matches) => matches.isEmpty
                ? _buildEmptySection('Nessun risultato recente')
                : Column(
                    children: matches.take(8).map((match) => _buildRecentMatchRow(match)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMatchRow(Match match) {
    final dateStr = '${match.date.day}/${match.date.month}';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Data
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              dateStr,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Squadra casa
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _buildTeamLogo(match.homeTeam.name, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.homeTeam.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Risultato
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              match.displayScore,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
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
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildTeamLogo(match.awayTeam.name, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarInfo(BuildContext context) {
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
                'INFORMAZIONI CALENDARIO',
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
          
          _buildInfoRow('📅', 'Le partite si giocano solitamente nei weekend'),
          _buildInfoRow('⏰', 'Orari: 15:00, 18:00, 20:45'),
          _buildInfoRow('🏟️', 'Serie A TIM 2024/2025 - 38 giornate'),
          _buildInfoRow('📺', 'Risultati aggiornati in tempo reale'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(String message) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.red.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
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

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Lun';
      case 2: return 'Mar';
      case 3: return 'Mer';
      case 4: return 'Gio';
      case 5: return 'Ven';
      case 6: return 'Sab';
      case 7: return 'Dom';
      default: return '';
    }
  }
}