import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers.dart';
import '../services/firestore_repo.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

// Provider per la classifica giocatori
final giocatoriClassificaProvider = FutureProvider<List<UserRanking>>((ref) async {
  final repo = ref.read(repoProvider);
  return await repo.getLeaderboard();
});

class ClassificaGiocatoriScreen extends ConsumerWidget {
  const ClassificaGiocatoriScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classificaAsync = ref.watch(giocatoriClassificaProvider);
    final currentUser = FirebaseAuth.instance.currentUser;

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
          'CLASSIFICA GIOCATORI',
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
            onPressed: () => ref.invalidate(giocatoriClassificaProvider),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: classificaAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, stack) => _buildErrorWidget(context, ref, error),
            data: (classifica) => _buildContent(context, classifica, currentUser?.uid, ref),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<UserRanking> classifica, String? currentUserId, WidgetRef ref) {
    if (classifica.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        
        // Header con info generali
        _buildClassificaHeader(classifica),
        
        const SizedBox(height: 20),
        
        // Podio (primi 3)
        if (classifica.length >= 3) ...[
          _buildPodio(classifica.take(3).toList()),
          const SizedBox(height: 20),
        ],
        
        // Lista completa
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(giocatoriClassificaProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: classifica.length,
              itemBuilder: (context, index) => _buildPlayerCard(
                classifica[index], 
                index + 1, 
                currentUserId,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassificaHeader(List<UserRanking> classifica) {
    final giocatoriAttivi = classifica.where((p) => p.isActive).length;
    final giocatoriEliminati = classifica.length - giocatoriAttivi;

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
              const Icon(Icons.leaderboard, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'CLASSIFICA GENERALE',
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
          
          // Statistiche
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Giocatori totali',
                  value: '${classifica.length}',
                  icon: Icons.people,
                  color: AppTheme.accentOrange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  label: 'Ancora in gioco',
                  value: '$giocatoriAttivi',
                  icon: Icons.sports_soccer,
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
                  label: 'Eliminati',
                  value: '$giocatoriEliminati',
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  label: 'Tasso sopravv.',
                  value: '${((giocatoriAttivi / classifica.length) * 100).toStringAsFixed(1)}%',
                  icon: Icons.trending_up,
                  color: Colors.blue,
                ),
              ),
            ],
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPodio(List<UserRanking> topThree) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade600, Colors.amber.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Text(
                'TOP 3 GIOCATORI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Podio con 2°, 1°, 3°
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Secondo posto
              if (topThree.length >= 2)
                Expanded(child: _buildPodiumPosition(topThree[1], 2, 80)),
              
              const SizedBox(width: 8),
              
              // Primo posto (più alto)
              Expanded(child: _buildPodiumPosition(topThree[0], 1, 100)),
              
              const SizedBox(width: 8),
              
              // Terzo posto
              if (topThree.length >= 3)
                Expanded(child: _buildPodiumPosition(topThree[2], 3, 60)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(UserRanking player, int position, double height) {
    Color medalColor;
    IconData medalIcon;
    
    switch (position) {
      case 1:
        medalColor = Colors.amber;
        medalIcon = Icons.looks_one;
        break;
      case 2:
        medalColor = Colors.grey.shade400;
        medalIcon = Icons.looks_two;
        break;
      case 3:
        medalColor = Colors.brown.shade300;
        medalIcon = Icons.looks_3;
        break;
      default:
        medalColor = Colors.grey;
        medalIcon = Icons.person;
    }

    return Column(
      children: [
        // Avatar giocatore
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: player.isActive ? AppTheme.accentOrange : Colors.grey,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: medalColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: medalColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              player.displayName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Nome giocatore
        Text(
          player.displayName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            decoration: player.isActive ? null : TextDecoration.lineThrough,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 4),
        
        // Vittorie
        Text(
          '${player.totalWins} vittorie',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Piedistallo
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: medalColor.withOpacity(0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(color: medalColor.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                medalIcon,
                color: medalColor,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                '$position°',
                style: TextStyle(
                  color: medalColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(UserRanking player, int position, String? currentUserId) {
    final isCurrentUser = player.uid == currentUserId;
    final isEliminated = !player.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentUser 
          ? AppTheme.accentOrange.withOpacity(0.2)
          : Colors.white.withOpacity(isEliminated ? 0.05 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser 
            ? AppTheme.accentOrange
            : Colors.white.withOpacity(isEliminated ? 0.1 : 0.2),
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Posizione
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getPositionColor(position),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '$position',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Avatar giocatore
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isEliminated 
                  ? Colors.grey.withOpacity(0.5)
                  : AppTheme.accentOrange,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isEliminated ? null : [
                  BoxShadow(
                    color: AppTheme.accentOrange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  player.displayName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: isEliminated ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Info giocatore
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.displayName,
                          style: TextStyle(
                            color: isEliminated 
                              ? Colors.white.withOpacity(0.5)
                              : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: isEliminated ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'TU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: isEliminated 
                          ? Colors.white.withOpacity(0.3)
                          : Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${player.totalWins} vittorie',
                        style: TextStyle(
                          color: isEliminated 
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.local_fire_department,
                        color: isEliminated 
                          ? Colors.white.withOpacity(0.3)
                          : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Streak: ${player.currentStreak}',
                        style: TextStyle(
                          color: isEliminated 
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isEliminated 
                  ? Colors.red.withOpacity(0.2)
                  : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEliminated 
                    ? Colors.red.withOpacity(0.5)
                    : Colors.green.withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isEliminated ? Icons.cancel : Icons.sports_soccer,
                    color: isEliminated ? Colors.red : Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isEliminated ? 'ELIM.' : 'ATTIVO',
                    style: TextStyle(
                      color: isEliminated ? Colors.red : Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  Color _getPositionColor(int position) {
    if (position == 1) return Colors.amber;
    if (position == 2) return Colors.grey.shade400;
    if (position == 3) return Colors.brown.shade300;
    if (position <= 10) return AppTheme.accentOrange;
    return Colors.grey;
  }

  Widget _buildEmptyState() {
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
              Icons.leaderboard,
              size: 64,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nessun giocatore trovato',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'La classifica verrà popolata\nquando inizieranno le partite',
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
              onPressed: () => ref.invalidate(giocatoriClassificaProvider),
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