import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers.dart';
import '../models/pick.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

class StoricoScelteScreen extends ConsumerWidget {
  const StoricoScelteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return _buildNotAuthenticatedView();
    }

    final userPicksAsync = ref.watch(userPicksProvider(user.uid));

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
          'STORICO SCELTE',
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
            onPressed: () => ref.invalidate(userPicksProvider(user.uid)),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: userPicksAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, stack) => _buildErrorState(error),
            data: (picks) => _buildContent(context, picks),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Pick> picks) {
    if (picks.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        
        // Header con statistiche
        _buildStatsHeader(picks),
        
        const SizedBox(height: 20),
        
        // Lista delle scelte
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // Refresh implementato tramite ref.invalidate nell'AppBar
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: picks.length,
              itemBuilder: (context, index) => _buildPickCard(picks[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(List<Pick> picks) {
    final completedPicks = picks.where((p) => !p.isPending).toList();
    final wins = completedPicks.where((p) => p.isWin).length;
    final jollyUsed = picks.where((p) => p.usedJolly).length;
    final currentStreak = picks.currentStreak;
    final successRate = picks.successRate;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'LE TUE STATISTICHE',
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
          
          // Statistiche in griglia 2x2
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Scelte totali',
                  value: '${picks.length}',
                  icon: Icons.sports_soccer,
                  color: AppTheme.accentOrange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  label: 'Vittorie',
                  value: '$wins',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Jolly usati',
                  value: '$jollyUsed',
                  icon: Icons.favorite,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  label: 'Streak attuale',
                  value: '$currentStreak',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Percentuale di successo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.percent, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Percentuale successo: ${successRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPickCard(Pick pick) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getPickBorderColor(pick).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Logo squadra e giornata
            Column(
              children: [
                _buildTeamLogo(pick.team),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'G${pick.giornata}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            // Informazioni scelta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pick.team,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildResultIcon(pick),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Giornata ${pick.giornata}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Status e info aggiuntive
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pick.resultDescription,
                          style: TextStyle(
                            color: _getPickTextColor(pick),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (pick.usedJolly)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite, color: Colors.red, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'JOLLY',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  // Data scelta
                  const SizedBox(height: 8),
                  Text(
                    'Scelta del ${_formatDate(pick.createdAt)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLogo(String teamName) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.accentOrange,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentOrange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          teamName.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildResultIcon(Pick pick) {
    IconData icon;
    Color color;
    
    if (pick.isPending) {
      icon = Icons.schedule;
      color = Colors.grey;
    } else if (pick.survived) {
      icon = pick.usedJolly ? Icons.shield : Icons.check_circle;
      color = pick.usedJolly ? Colors.orange : Colors.green;
    } else {
      icon = Icons.cancel;
      color = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Color _getPickBorderColor(Pick pick) {
    if (pick.isPending) return Colors.grey;
    if (pick.survived) return pick.usedJolly ? Colors.orange : Colors.green;
    return Colors.red;
  }

  Color _getPickTextColor(Pick pick) {
    if (pick.isPending) return Colors.white70;
    if (pick.survived) return pick.usedJolly ? Colors.orange : Colors.green;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(80),
            ),
            child: const Icon(
              Icons.sports_soccer,
              size: 64,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nessuna scelta ancora',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Le tue scelte appariranno qui\nuna volta che inizierai a giocare',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.sports_soccer),
            label: const Text('Fai la tua prima scelta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotAuthenticatedView() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.login,
                size: 64,
                color: Colors.white70,
              ),
              const SizedBox(height: 24),
              const Text(
                'Accesso richiesto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Devi essere autenticato per\nvedere le tue scelte',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
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
              'Impossibile caricare le tue scelte',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}