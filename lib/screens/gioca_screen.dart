import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'scegli_squadra_screen.dart';
import 'storico_scelte_screen.dart';
import 'classifica_giocatori_screen.dart';

class GiocaScreen extends ConsumerWidget {
  const GiocaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'GIOCA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Header
              Text(
                'LAST MAN STANDING',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Card: Scegli Squadra
              _buildGameCard(
                context,
                title: 'Scegli Squadra',
                subtitle: 'Fai la tua scelta per questa giornata',
                icon: Icons.sports_soccer,
                gradient: AppTheme.dangerGradient,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScegliSquadraScreen(),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Card: Storico Scelte
              _buildGameCard(
                context,
                title: 'Storico Scelte',
                subtitle: 'Le tue scelte dalle giornate precedenti',
                icon: Icons.history,
                gradient: AppTheme.successGradient,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StoricoScelteScreen(),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Card: Classifica Giocatori
              _buildGameCard(
                context,
                title: 'Classifica Giocatori',
                subtitle: 'Vedi come stai andando rispetto agli altri',
                icon: Icons.leaderboard,
                gradient: AppTheme.goldGradient,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ClassificaGiocatoriScreen(),
                  ),
                ),
              ),

              const Spacer(),

              // Footer info
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: AppTheme.glassCard,
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: AppSizes.iconSm,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Ricorda: puoi scegliere solo squadre non ancora utilizzate!',
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
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, color: Colors.white, size: AppSizes.iconLg),
            ),
            const SizedBox(width: AppSpacing.lg),
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
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.8),
              size: AppSizes.iconSm,
            ),
          ],
        ),
      ),
    );
  }
}
