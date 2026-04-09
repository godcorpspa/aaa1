import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../models/league_models.dart';
import '../shared_providers.dart';
import '../providers/league_providers.dart';
import 'create_league_screen.dart';
import 'join_league_screen.dart';

class ProfiloScreen extends ConsumerWidget {
  const ProfiloScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final userDataAsync = ref.watch(userDataProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: userDataAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          ),
          error: (e, _) => _errorView(e),
          data: (userData) {
            if (user == null) return _notAuthView();
            return _Content(user: user, userData: userData);
          },
        ),
      ),
    );
  }

  Widget _errorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Errore nel caricamento del profilo',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notAuthView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login_rounded,
              size: 48, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Accesso richiesto',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Devi essere autenticato per\naccedere al profilo',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.user, required this.userData});
  final User user;
  final dynamic userData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userLeagues = ref.watch(currentUserLeaguesProvider);
    final selectedLeague = ref.watch(selectedLeagueProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),

          const Text(
            'Profilo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Avatar + user info
          _buildHeader(context),

          const SizedBox(height: AppSpacing.lg),

          // Le Mie Leghe
          _buildLeaguesSection(context, ref, userLeagues, selectedLeague),

          const SizedBox(height: AppSpacing.lg),

          // Settings
          _buildSettings(context),

          const SizedBox(height: AppSpacing.lg),

          // Logout
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
              label: const Text(
                'Esci',
                style: TextStyle(color: AppTheme.errorRed),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: AppTheme.errorRed.withValues(alpha: 0.25)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final displayName =
        user.displayName ?? userData?.displayName ?? 'Utente';
    final email = user.email ?? '';
    final isActive = userData?.isActive ?? true;
    final initials = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryRed.withValues(alpha: 0.2)
                  : AppTheme.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? AppTheme.primaryRed.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: Center(
              child: user.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        user.photoURL!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  : Text(
                      initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700),
                    ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        (isActive ? AppTheme.successGreen : AppTheme.errorRed)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                  ),
                  child: Text(
                    isActive ? 'ATTIVO' : 'ELIMINATO',
                    style: TextStyle(
                      color: isActive
                          ? AppTheme.successGreen
                          : AppTheme.errorRed,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaguesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<LastManStandingLeague>> userLeagues,
    String? selectedLeague,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded,
                  color: Colors.white.withValues(alpha: 0.7), size: 20),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Le mie leghe',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          userLeagues.when(
            loading: () => const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.primaryRed),
            ),
            error: (_, __) => Text(
              'Errore nel caricamento',
              style: TextStyle(
                  color: AppTheme.errorRed.withValues(alpha: 0.8)),
            ),
            data: (leagues) {
              if (leagues.isEmpty) {
                return _noLeagues(context);
              }
              return Column(
                children: [
                  ...leagues.map((l) => _leagueItem(
                        context,
                        ref,
                        l,
                        isSelected: l.id == selectedLeague,
                      )),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const CreateLeagueScreen()),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Crea'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const JoinLeagueScreen()),
                          ),
                          icon: const Icon(Icons.group_add_rounded,
                              size: 18),
                          label: const Text('Unisciti'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _leagueItem(
    BuildContext context,
    WidgetRef ref,
    LastManStandingLeague league, {
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () {
            ref
                .read(selectedLeagueProvider.notifier)
                .selectLeague(league.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Lega "${league.name}" selezionata')),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryRed.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryRed.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryRed.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius:
                        BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    league.isPrivate
                        ? Icons.lock_rounded
                        : Icons.public_rounded,
                    color: isSelected
                        ? AppTheme.primaryRed
                        : Colors.white.withValues(alpha: 0.5),
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        league.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${league.currentParticipants} partecipanti',
                        style: TextStyle(
                          color:
                              Colors.white.withValues(alpha: 0.35),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded,
                      color: AppTheme.primaryRed, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _noLeagues(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Icon(Icons.groups_outlined,
              size: 40, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Non fai parte di nessuna lega',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const JoinLeagueScreen()),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Unisciti o Crea una Lega'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Impostazioni',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          _settingsRow(
            Icons.notifications_rounded,
            'Notifiche',
            AppTheme.accentCyan,
            trailing: Switch(value: true, onChanged: (_) {}),
          ),

          Divider(
            color: Colors.white.withValues(alpha: 0.04),
            height: AppSpacing.md,
          ),

          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: () => _showAbout(context),
            child: _settingsRow(
              Icons.info_outline_rounded,
              'Informazioni App',
              Colors.white.withValues(alpha: 0.5),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsRow(IconData icon, String label, Color iconColor,
      {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma'),
        content: const Text('Sei sicuro di voler uscire?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
            },
            child: const Text('Esci',
                style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Last Man Standing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _aboutRow('Versione', '1.0.0'),
            _aboutRow('Sviluppatore', 'Last Man Standing Team'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
