import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/league_models.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

class ClassificaScreen extends ConsumerWidget {
  const ClassificaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(serieAStandingsProvider);

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
          'CLASSIFICA',
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
            onPressed: () => ref.invalidate(serieAStandingsProvider),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Header stagione
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'SERIE A TIM 2024/2025',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Colors.white70,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Classifica
              Expanded(
                child: standingsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (error, stack) => _buildErrorWidget(context, ref, error),
                  data: (standings) => _buildStandingsTable(context, standings),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandingsTable(BuildContext context, List<LeagueStanding> standings) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header tabella
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.accentOrange,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: const [
                SizedBox(width: 40, child: Text('#', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('SQUADRA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                SizedBox(width: 30, child: Text('P', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 30, child: Text('V', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 30, child: Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 30, child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 40, child: Text('DIFF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 40, child: Text('PTS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          
          // Righe squadre
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: standings.length,
              itemBuilder: (context, index) {
                final standing = standings[index];
                return _buildTeamRow(context, standing, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow(BuildContext context, LeagueStanding standing, int index) {
    Color? backgroundColor;
    
    // Colori per posizioni europee e retrocessione
    if (standing.position <= 2) {
      backgroundColor = Colors.green.withOpacity(0.1); // Champions/Europa League
    } else if (standing.position >= 9) {
      backgroundColor = Colors.red.withOpacity(0.1); // Zona retrocessione
    }

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Posizione
          SizedBox(
            width: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPositionColor(standing.position),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${standing.position}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Nome squadra
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Logo placeholder
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      standing.team.name.substring(0, 1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    standing.team.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Statistiche
          SizedBox(width: 30, child: Text('${standing.played}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
          SizedBox(width: 30, child: Text('${standing.wins}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
          SizedBox(width: 30, child: Text('${standing.draws}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
          SizedBox(width: 30, child: Text('${standing.losses}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
          
          // Differenza reti
          SizedBox(
            width: 40,
            child: Text(
              standing.goalDifference >= 0 ? '+${standing.goalDifference}' : '${standing.goalDifference}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: standing.goalDifference >= 0 ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Punti
          SizedBox(
            width: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${standing.points}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(int position) {
    if (position <= 4) return Colors.green; // Champions League
    if (position <= 5) return Colors.blue; // Europa League  
    if (position <= 6) return Colors.orange; // Conference League
    if (position >= 18) return Colors.red; // Retrocessione
    return Colors.grey;
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, Object error) {
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
              'Impossibile caricare la classifica',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(serieAStandingsProvider),
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