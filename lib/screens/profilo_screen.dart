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
                size: 48, color: Colors.white.withValues(alpha: 0.5)),
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
              size: 56, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Accesso richiesto',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Devi essere autenticato per\naccedere al profilo',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main content (needs ref for league selection)
// ---------------------------------------------------------------------------
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
        children: [
          const SizedBox(height: AppSpacing.md),

          // Avatar + user info
          _buildHeader(context),

          const SizedBox(height: AppSpacing.xl),

          // Le Mie Leghe
          _buildLeaguesSection(context, ref, userLeagues, selectedLeague),

          const SizedBox(height: AppSpacing.xl),

          // Settings
          _buildSettings(context),

          const SizedBox(height: AppSpacing.xl),

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
                    color: AppTheme.errorRed.withValues(alpha: 0.4)),
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

  // ---------- Header ----------
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
      decoration: AppTheme.elevatedCard,
      child: Column(
        children: [
          // Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryRed
                  : AppTheme.surfaceElevated,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isActive ? AppTheme.primaryRed : Colors.black)
                      .withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: user.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        user.photoURL!,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  : Text(
                      initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700),
                    ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            displayName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700),
          ),

          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: (isActive ? AppTheme.successGreen : AppTheme.errorRed)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: (isActive ? AppTheme.successGreen : AppTheme.errorRed)
                    .withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color:
                      isActive ? AppTheme.successGreen : AppTheme.errorRed,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isActive ? 'ATTIVO' : 'ELIMINATO',
                  style: TextStyle(
                    color: isActive
                        ? AppTheme.successGreen
                        : AppTheme.errorRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Leagues ----------
  Widget _buildLeaguesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<LastManStandingLeague>> userLeagues,
    String? selectedLeague,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'LE MIE LEGHE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
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
                  ? AppTheme.primaryRed.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryRed
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryRed
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    league.isPrivate
                        ? Icons.lock_rounded
                        : Icons.public_rounded,
                    color: Colors.white,
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
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${league.currentParticipants} partecipanti',
                        style: TextStyle(
                          color:
                              Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _noLeagues(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(Icons.groups_outlined,
              size: 44, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Non fai parte di nessuna lega',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
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

  // ---------- Settings ----------
  Widget _buildSettings(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IMPOSTAZIONI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Notifications toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.infoBlue.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.notifications_rounded,
                    color: AppTheme.infoBlue, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'Notifiche',
                  style: TextStyle(
                      color: Colors.white, fontSize: 15),
                ),
              ),
              Switch(value: true, onChanged: (_) {}),
            ],
          ),

          Divider(
            color: Colors.white.withValues(alpha: 0.08),
            height: AppSpacing.lg,
          ),

          // About
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: () => _showAbout(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Icons.info_outline_rounded,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Text(
                      'Informazioni App',
                      style: TextStyle(
                          color: Colors.white, fontSize: 15),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Dialogs ----------
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
