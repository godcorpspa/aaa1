import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import 'classifica_screen.dart';
import 'calendario_screen.dart';
import 'risultati_live_screen.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'STATISTICHE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Header
                Text(
                  'SERIE A TIM',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Colors.white70,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Card Classifica
                _buildStatsCard(
                  context,
                  title: 'Classifica',
                  subtitle: 'Visualizza la classifica aggiornata',
                  icon: Icons.leaderboard,
                  gradient: AppTheme.successGradient,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClassificaScreen(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Card Calendario
                _buildStatsCard(
                  context,
                  title: 'Calendario',
                  subtitle: 'Prossime partite e risultati recenti',
                  icon: Icons.calendar_today,
                  gradient: AppTheme.warningGradient,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalendarioScreen(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Card Risultati Live
                _buildStatsCard(
                  context,
                  title: 'Risultati Live',
                  subtitle: 'Partite live, finite e prossime',
                  icon: Icons.sports_soccer,
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RisultatiLiveScreen(),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Footer info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white.withOpacity(0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Dati aggiornati in tempo reale del campionato di Serie A',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}