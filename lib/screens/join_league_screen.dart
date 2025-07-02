import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ← AGGIUNTO per logout
import '../widgets/gradient_background.dart';
import '../theme/app_theme.dart';
import '../providers.dart'; // Per authServiceProvider (opzionale)
import '../shared_providers.dart'; // ← AGGIUNTO per hasLeaguesProvider
import 'public_leagues_screen.dart';

class JoinLeagueScreen extends ConsumerStatefulWidget {
  const JoinLeagueScreen({super.key});

  @override
  ConsumerState<JoinLeagueScreen> createState() => _JoinLeagueScreenState();
}

class _JoinLeagueScreenState extends ConsumerState<JoinLeagueScreen>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Avvia le animazioni
    _bounceController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // ← AGGIUNTO per rimuovere la freccia
        title: const Text(
          'Unisciti ad una Lega',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          // PULSANTE LOGOUT
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.white,
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView( // ← AGGIUNTO ScrollView
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox( // ← AGGIUNTO per garantire altezza minima
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          MediaQuery.of(context).padding.bottom - 48,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20), // Ridotto da 40
                  
                  // Shield Icon con animazione
                  ScaleTransition(
                    scale: _bounceAnimation,
                    child: Container(
                      width: 100, // Ridotto da 120
                      height: 100, // Ridotto da 120
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(50), // Aggiornato
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield,
                        size: 50, // Ridotto da 60
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30), // Ridotto da 40
                  
                  // Titolo principale con nome utente
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final authState = ref.watch(authProvider);
                        
                        return authState.when(
                          data: (user) {
                            // Prende il displayName dell'utente
                            final userName = user?.displayName ?? 'Utente';
                            
                            return Text(
                              'Benvenuto $userName, sei pronto\nper una nuova sfida.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            );
                          },
                          loading: () => const Text(
                            'Benvenuto, sei pronto\nper una nuova sfida.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          error: (_, __) => const Text(
                            'Benvenuto, sei pronto\nper una nuova sfida.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 40), // Ridotto da 60
                  
                  // Sezione Lega Privata
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildLeagueSection(
                      title: 'Sai già a quale Lega unirti, hai ricevuto un invito o possiedi la parola d\'ordine',
                      buttonText: 'Unisciti a Lega privata',
                      buttonColor: AppTheme.accentOrange,
                      onPressed: () => _showJoinPrivateLeagueDialog(),
                    ),
                  ),
                  
                  const SizedBox(height: 30), // Ridotto da 40
                  
                  // Sezione Lega Pubblica
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildLeagueSection(
                      title: 'Cerca una Lega a cui unirti e trova nuovi amici, magari della tua zona, con cui giocare.',
                      buttonText: 'Unisciti a Lega pubblica',
                      buttonColor: AppTheme.accentOrange,
                      onPressed: () => _navigateToPublicLeagues(),
                    ),
                  ),
                  const SizedBox(height: 30), // Aggiunto spazio fisso
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeagueSection({
    required String title,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: buttonColor.withOpacity(0.3),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinPrivateLeagueDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _JoinPrivateLeagueDialog(),
    );
  }

  void _navigateToPublicLeagues() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PublicLeaguesScreen(),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Logout'),
        content: const Text('Sei sicuro di voler uscire dal tuo account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Chiudi dialog
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _performLogout() async {
    try {
      // Usa Firebase Auth direttamente invece del provider
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        // Mostra messaggio di successo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout effettuato con successo'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Torna alla schermata di welcome
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _JoinPrivateLeagueDialog extends ConsumerStatefulWidget { // ← CAMBIATO da StatefulWidget
  @override
  ConsumerState<_JoinPrivateLeagueDialog> createState() => _JoinPrivateLeagueDialogState(); // ← CAMBIATO
}

class _JoinPrivateLeagueDialogState extends ConsumerState<_JoinPrivateLeagueDialog> { // ← CAMBIATO
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: AppTheme.accentOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Unisciti a Lega Privata',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Codice invito
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Codice invito',
                hintText: 'Inserisci il codice della lega',
                prefixIcon: const Icon(Icons.vpn_key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            
            const SizedBox(height: 16),
            
            // Password (opzionale)
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password (se richiesta)',
                hintText: 'Inserisci la password',
                prefixIcon: const Icon(Icons.password),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Pulsanti azione
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Annulla'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _joinPrivateLeague,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
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

  void _joinPrivateLeague() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Inserisci il codice invito');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simula chiamata API per ora
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.pop(context);
        
        // Imposta che QUESTO UTENTE specifico ha ora una lega
        final user = ref.read(authProvider).valueOrNull;
        if (user != null) {
          final currentStatus = ref.read(userLeaguesStatusProvider);
          ref.read(userLeaguesStatusProvider.notifier).state = {
            ...currentStatus,
            user.uid: true, // Solo per questo utente
          };
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ti sei unito alla lega con successo!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // L'AuthGate si aggiornerà automaticamente e mostrerà la MainLayout
      }
    } catch (e) {
      setState(() => _errorMessage = 'Errore nell\'unirsi alla lega: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}