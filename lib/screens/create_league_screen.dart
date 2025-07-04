import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_man_standing/models/league_models.dart' show LeagueSettings, LastManStandingLeague;
import 'package:last_man_standing/providers/league_providers.dart' show userLeaguesProvider, leagueServiceProvider;
import '../widgets/gradient_background.dart';
import '../theme/app_theme.dart';

// Screen per creare una nuova lega Last Man Standing

class CreateLeagueScreen extends ConsumerStatefulWidget {
  const CreateLeagueScreen({super.key});

  @override
  ConsumerState<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends ConsumerState<CreateLeagueScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPrivate = false;
  bool _requirePassword = false;
  bool _allowDoubleDown = true;
  bool _allowJolly = true;
  bool _enableThemedRounds = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    
    // Valori di default
    _maxParticipantsController.text = '50';
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Crea una nuova Lega',
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Header con icona
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    const Text(
                      'Crea la tua Lega personalizzata',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Invita i tuoi amici e personalizza le regole del gioco',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Nome Lega
                    _buildInputField(
                      controller: _nameController,
                      label: 'Nome della Lega',
                      hint: 'es. Champions League Amici',
                      prefixIcon: Icons.sports_soccer,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Il nome della lega è obbligatorio';
                        }
                        if (value.trim().length < 3) {
                          return 'Il nome deve essere almeno 3 caratteri';
                        }
                        if (value.trim().length > 30) {
                          return 'Il nome non può superare 30 caratteri';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Descrizione
                    _buildInputField(
                      controller: _descriptionController,
                      label: 'Descrizione (opzionale)',
                      hint: 'Descrivi la tua lega...',
                      prefixIcon: Icons.description,
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Max partecipanti
                    _buildInputField(
                      controller: _maxParticipantsController,
                      label: 'Numero massimo partecipanti',
                      hint: '50',
                      prefixIcon: Icons.people,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Numero partecipanti obbligatorio';
                        }
                        final num = int.tryParse(value);
                        if (num == null || num < 2) {
                          return 'Minimo 2 partecipanti';
                        }
                        if (num > 1000) {
                          return 'Massimo 1000 partecipanti';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Impostazioni Privacy
                    _buildSectionHeader('Privacy e Accesso'),
                    _buildPrivacySettings(),
                    
                    const SizedBox(height: 30),
                    
                    // Regole di Gioco
                    _buildSectionHeader('Regole di Gioco'),
                    _buildGameRulesSettings(),
                    
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      _buildErrorMessage(),
                    ],
                    
                    const SizedBox(height: 40),
                    
                    // Pulsante Crea
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createLeague,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'CREA LEGA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      maxLength: maxLength,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null 
          ? Icon(prefixIcon, color: Colors.white70) 
          : null,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white38),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        counterStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.accentOrange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Lega Privata',
            subtitle: 'Solo tramite invito o codice',
            value: _isPrivate,
            onChanged: (value) => setState(() => _isPrivate = value),
            icon: Icons.lock,
          ),
          
          if (_isPrivate) ...[
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Richiedi Password',
              subtitle: 'Password aggiuntiva per entrare',
              value: _requirePassword,
              onChanged: (value) => setState(() => _requirePassword = value),
              icon: Icons.password,
            ),
            
            if (_requirePassword) ...[
              const SizedBox(height: 16),
              _buildInputField(
                controller: _passwordController,
                label: 'Password Lega',
                hint: 'Inserisci una password',
                prefixIcon: Icons.key,
                validator: (value) {
                  if (_requirePassword && (value == null || value.isEmpty)) {
                    return 'Password obbligatoria';
                  }
                  if (_requirePassword && value != null && value.length < 4) {
                    return 'Password troppo corta (min 4 caratteri)';
                  }
                  return null;
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildGameRulesSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Abilita Jolly Vita',
            subtitle: 'I giocatori possono acquistare jolly',
            value: _allowJolly,
            onChanged: (value) => setState(() => _allowJolly = value),
            icon: Icons.favorite,
          ),
          
          const SizedBox(height: 16),
          
          _buildSwitchTile(
            title: 'Abilita Scelta Doppia',
            subtitle: 'Permetti scelta di due squadre',
            value: _allowDoubleDown,
            onChanged: (value) => setState(() => _allowDoubleDown = value),
            icon: Icons.add_circle,
          ),
          
          const SizedBox(height: 16),
          
          _buildSwitchTile(
            title: 'Giornate a Tema',
            subtitle: 'Giornate speciali ogni 4 turni',
            value: _enableThemedRounds,
            onChanged: (value) => setState(() => _enableThemedRounds = value),
            icon: Icons.palette,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.accentOrange, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accentOrange,
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createLeague() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Usa il servizio leghe per creare
      final league = await ref.read(leagueServiceProvider).createLeague(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        maxParticipants: int.parse(_maxParticipantsController.text),
        isPrivate: _isPrivate,
        requirePassword: _requirePassword,
        password: _requirePassword ? _passwordController.text : null,
        settings: LeagueSettings(
          allowJolly: _allowJolly,
          allowDoubleDown: _allowDoubleDown,
          enableThemedRounds: _enableThemedRounds,
        ),
      );

      if (mounted) {
        // Forza un refresh del provider delle leghe
        ref.invalidate(userLeaguesProvider);
        
        // Se la lega è privata, mostra il codice invito
        if (league.isPrivate && league.inviteCode != null) {
          await _showInviteCodeDialog(league);
        } else {
          // Mostra messaggio di successo per leghe pubbliche
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lega "${league.name}" creata con successo!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Attendi brevemente che lo stato si aggiorni
        await Future.delayed(const Duration(milliseconds: 500));

        // Torna alla home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Errore nella creazione della lega: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showInviteCodeDialog(LastManStandingLeague league) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Lega Creata con Successo!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'La tua lega "${league.name}" è stata creata!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentOrange.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'CODICE INVITO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentOrange,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        league.inviteCode!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentOrange,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: league.inviteCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Codice copiato negli appunti!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.copy,
                          color: AppTheme.accentOrange,
                        ),
                        tooltip: 'Copia codice',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Condividi questo codice con i tuoi amici\nper farli unire alla lega.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            if (league.requirePassword) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Ricorda di comunicare anche la password!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Copia il testo completo negli appunti
              final shareText = 'Unisciti alla mia lega "${league.name}" su Last Man Standing!\n\n'
                  'Codice invito: ${league.inviteCode}\n'
                  '${league.requirePassword ? '\nRicordati di chiedere la password!' : ''}';
              
              Clipboard.setData(ClipboardData(text: shareText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Testo copiato negli appunti!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Copia Invito'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}