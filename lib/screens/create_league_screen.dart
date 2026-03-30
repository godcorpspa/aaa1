import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/league_models.dart' show LeagueSettings, LastManStandingLeague;
import '../providers/league_providers.dart';

class CreateLeagueScreen extends ConsumerStatefulWidget {
  const CreateLeagueScreen({super.key});

  @override
  ConsumerState<CreateLeagueScreen> createState() =>
      _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends ConsumerState<CreateLeagueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxCtrl = TextEditingController(text: '50');
  final _pwCtrl = TextEditingController();

  bool _isPrivate = false;
  bool _requirePassword = false;
  bool _allowDoubleChoice = true;
  bool _allowGoldTicket = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _maxCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createLeagueStateProvider);

    ref.listen(createLeagueStateProvider, (prev, next) {
      if (next.status == CreateLeagueStatus.success &&
          next.createdLeague != null) {
        ref.invalidate(currentUserLeaguesProvider);
        _showSuccessDialog(next.createdLeague!);
      } else if (next.status == CreateLeagueStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Errore')),
        );
      }
    });

    final isLoading = createState.status == CreateLeagueStatus.loading;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Crea una nuova Lega'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nome della Lega',
                    hintText: 'es. Champions League Amici',
                    prefixIcon: Icon(Icons.sports_soccer_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Il nome della lega e\' obbligatorio';
                    }
                    if (v.trim().length < 3) return 'Minimo 3 caratteri';
                    if (v.trim().length > 30) return 'Massimo 30 caratteri';
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione (opzionale)',
                    hintText: 'Descrivi la tua lega...',
                    prefixIcon: Icon(Icons.description_rounded),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Max participants
                TextFormField(
                  controller: _maxCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Numero massimo partecipanti',
                    prefixIcon: Icon(Icons.people_rounded),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 2) return 'Minimo 2 partecipanti';
                    if (n > 1000) return 'Massimo 1000 partecipanti';
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // Privacy section
                _sectionHeader('Privacy e Accesso'),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: AppTheme.glassCard,
                  child: Column(
                    children: [
                      _switchRow(
                        icon: Icons.lock_rounded,
                        title: 'Lega Privata',
                        subtitle: 'Solo tramite invito o codice',
                        value: _isPrivate,
                        onChanged: (v) =>
                            setState(() => _isPrivate = v),
                      ),
                      if (_isPrivate) ...[
                        const SizedBox(height: AppSpacing.md),
                        _switchRow(
                          icon: Icons.password_rounded,
                          title: 'Richiedi Password',
                          subtitle: 'Password aggiuntiva per entrare',
                          value: _requirePassword,
                          onChanged: (v) =>
                              setState(() => _requirePassword = v),
                        ),
                        if (_requirePassword) ...[
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _pwCtrl,
                            style: const TextStyle(color: Colors.white),
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password Lega',
                              hintText: 'Inserisci una password',
                              prefixIcon: Icon(Icons.key_rounded),
                            ),
                            validator: (v) {
                              if (_requirePassword &&
                                  (v == null || v.isEmpty)) {
                                return 'Password obbligatoria';
                              }
                              if (_requirePassword &&
                                  v != null &&
                                  v.length < 4) {
                                return 'Minimo 4 caratteri';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Game rules section
                _sectionHeader('Regole di Gioco'),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: AppTheme.glassCard,
                  child: Column(
                    children: [
                      _switchRow(
                        icon: Icons.add_circle_rounded,
                        title: 'Scelta Doppia',
                        subtitle:
                            'Permetti la scelta di due squadre',
                        value: _allowDoubleChoice,
                        onChanged: (v) =>
                            setState(() => _allowDoubleChoice = v),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _switchRow(
                        icon: Icons.stars_rounded,
                        title: 'Gold Ticket',
                        subtitle:
                            'I giocatori possono usare Gold Tickets',
                        value: _allowGoldTicket,
                        onChanged: (v) =>
                            setState(() => _allowGoldTicket = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Create button
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.buttonHeight,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _create,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'CREA LEGA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primaryRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child:
              Icon(icon, color: AppTheme.primaryRed, size: AppSizes.iconSm),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  void _create() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(createLeagueStateProvider.notifier).createLeague(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          maxParticipants: int.parse(_maxCtrl.text),
          isPrivate: _isPrivate,
          requirePassword: _requirePassword,
          password: _requirePassword ? _pwCtrl.text : null,
          settings: LeagueSettings(
            allowDoubleChoice: _allowDoubleChoice,
            allowGoldTicket: _allowGoldTicket,
          ),
        );
  }

  void _showSuccessDialog(LastManStandingLeague league) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.successGreen, size: 56),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Lega Creata!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '"${league.name}" e\' stata creata con successo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              if (league.inviteCode != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color:
                          AppTheme.accentGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'CODICE INVITO',
                        style: TextStyle(
                          color: AppTheme.accentGold
                              .withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text(
                            league.inviteCode!,
                            style: const TextStyle(
                              color: AppTheme.accentGold,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: league.inviteCode!));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Codice copiato!'),
                                ),
                              );
                            },
                            icon: const Icon(
                                Icons.copy_rounded,
                                color: AppTheme.accentGold,
                                size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Condividi questo codice con i tuoi amici.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(createLeagueStateProvider.notifier).reset();
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
