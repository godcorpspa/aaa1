import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/league_providers.dart';
import 'public_leagues_screen.dart';
import 'create_league_screen.dart';

class JoinLeagueScreen extends ConsumerWidget {
  const JoinLeagueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Unisciti ad una Lega'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),

              // Create League
              _SectionCard(
                icon: Icons.add_circle_outline_rounded,
                title: 'Crea una nuova Lega',
                description:
                    'Organizza il tuo torneo e scegli le regole. '
                    'Invita i tuoi amici o trovane nuovi online.',
                buttonLabel: 'Crea Lega',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateLeagueScreen()),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Join Private
              _SectionCard(
                icon: Icons.lock_outline_rounded,
                title: 'Unisciti a Lega privata',
                description:
                    'Hai ricevuto un codice invito? '
                    'Inseriscilo per unirti alla lega dei tuoi amici.',
                buttonLabel: 'Inserisci Codice',
                onPressed: () =>
                    _showJoinPrivateDialog(context, ref),
              ),

              const SizedBox(height: AppSpacing.md),

              // Join Public
              _SectionCard(
                icon: Icons.people_outline_rounded,
                title: 'Unisciti a Lega pubblica',
                description:
                    'Esplora le leghe pubbliche aperte e '
                    'trova quella perfetta per te.',
                buttonLabel: 'Esplora Leghe',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PublicLeaguesScreen()),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinPrivateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const _JoinPrivateDialog(),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card
// ---------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppTheme.elevatedCard,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, color: AppTheme.primaryRed, size: 28),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private league join dialog
// ---------------------------------------------------------------------------
class _JoinPrivateDialog extends ConsumerStatefulWidget {
  const _JoinPrivateDialog();

  @override
  ConsumerState<_JoinPrivateDialog> createState() =>
      _JoinPrivateDialogState();
}

class _JoinPrivateDialogState extends ConsumerState<_JoinPrivateDialog> {
  final _codeCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(joinLeagueStateProvider, (prev, next) {
      if (next.status == JoinLeagueStatus.success) {
        ref.invalidate(currentUserLeaguesProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ti sei unito alla lega con successo!'),
          ),
        );
      } else if (next.status == JoinLeagueStatus.error) {
        setState(() {
          _loading = false;
          _error = next.errorMessage;
        });
      }
    });

    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: AppTheme.primaryRed, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text(
                    'Unisciti a Lega Privata',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Code input
            TextField(
              controller: _codeCtrl,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Codice Invito',
                hintText: 'es. LMS123ABC',
                prefixIcon: Icon(Icons.vpn_key_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppSpacing.md),

            // Password input
            TextField(
              controller: _pwCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Password (se richiesta)',
                prefixIcon: Icon(Icons.password_rounded),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: AppTheme.statusCard(StatusType.error),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppTheme.errorRed, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            color: AppTheme.errorRed, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _codeCtrl.text.trim().isEmpty || _loading
                            ? null
                            : _join,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Unisciti'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _join() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(joinLeagueStateProvider.notifier)
          .joinLeagueByInviteCode(
            inviteCode: _codeCtrl.text.trim(),
            password: _pwCtrl.text.trim().isEmpty
                ? null
                : _pwCtrl.text.trim(),
          );
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }
}
