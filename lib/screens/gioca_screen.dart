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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

              const Text(
                'Gioca',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Last Man Standing',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Scegli Squadra - primary action
              _GiocaCard(
                title: 'Scegli Squadra',
                subtitle: 'Fai la tua scelta per questa giornata',
                icon: Icons.sports_soccer_rounded,
                isPrimary: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScegliSquadraScreen(),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              _GiocaCard(
                title: 'Storico Scelte',
                subtitle: 'Le tue scelte dalle giornate precedenti',
                icon: Icons.history_rounded,
                iconColor: AppTheme.accentCyan,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StoricoScelteScreen(),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              _GiocaCard(
                title: 'Classifica Giocatori',
                subtitle: 'Vedi come stai andando rispetto agli altri',
                icon: Icons.emoji_events_rounded,
                iconColor: AppTheme.accentGold,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ClassificaGiocatoriScreen(),
                  ),
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: AppTheme.glassCard,
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Puoi scegliere solo squadre non ancora utilizzate',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 12,
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
}

class _GiocaCard extends StatelessWidget {
  const _GiocaCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.primaryRed;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isPrimary ? null : AppTheme.surfaceCard,
            gradient: isPrimary
                ? const LinearGradient(
                    colors: [Color(0xFF2A1520), Color(0xFF1A1A24)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isPrimary
                  ? AppTheme.primaryRed.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.25),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
