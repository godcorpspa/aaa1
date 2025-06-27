import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';  
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'providers.dart';
import 'widgets/team_picker_dialog.dart';
import 'models/matchday.dart';
import 'models/user_data.dart';
import 'models/pick.dart';
import 'screens/welcome_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/scegli_screen.dart';
import 'firebase_options.dart';

// Costanti estratte per migliore manutenibilità
class AppConstants {
  static const List<String> mockTeams = [
    'Atalanta', 'Bologna', 'Cagliari', 'Empoli', 'Fiorentina', 'Genoa',
    'Inter', 'Juventus', 'Lazio', 'Lecce', 'Milan', 'Monza',
    'Napoli', 'Roma', 'Salernitana', 'Sassuolo', 'Torino', 'Udinese',
  ];
  
  static const String appTitle = 'Last Man Standing';
  static const String homeTitle = 'LAST MAN STANDING - SERIE A';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Log dell'errore di inizializzazione Firebase
    debugPrint('Errore inizializzazione Firebase: $e');
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('it'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      title: AppConstants.appTitle,
      theme: AppTheme.theme, // Usa il tema definito
      home: const AuthGate(),
    );
  }
}

/// Widget che gestisce l'autenticazione e la navigazione iniziale
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return authState.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        backgroundColor: Color(0xFFB71C1C),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Errore di connessione: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(authProvider),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      ),
      data: (user) => user != null 
        ? const HomePage() 
        : const WelcomeScreen(),
    );
  }
}

/// HomePage ottimizzata con migliore gestione degli stati
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> 
    with WidgetsBindingObserver {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pausa/riprendi timer in base al ciclo di vita dell'app
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed && !_isDisposed) {
      // Riavvia il timer quando l'app torna in primo piano
      final matchdayAsync = ref.read(matchdayProvider);
      matchdayAsync.whenData((md) => _startTimer(md.deadline));
    }
  }

  void _startTimer(DateTime deadline) {
    _timer?.cancel();
    if (_isDisposed) return;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isDisposed) return;
      
      final diff = deadline.difference(DateTime.now());
      final newRemaining = diff.isNegative ? Duration.zero : diff;
      
      if (mounted) {
        setState(() => _remaining = newRemaining);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchdayAsync = ref.watch(matchdayProvider);
    final userAsync = ref.watch(userDataProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const _BottomNav(currentIndex: 0),
      appBar: _buildAppBar(context),
      extendBodyBehindAppBar: true,
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(gradient: AppTheme.gradient),
        child: SafeArea(
          child: matchdayAsync.when(
            loading: () => _buildLoadingWidget(),
            error: (error, stack) => _buildErrorWidget(error),
            data: (matchday) {
              // Avvia timer solo se necessario
              if (_remaining == Duration.zero && !matchday.deadline.isBefore(DateTime.now())) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _startTimer(matchday.deadline);
                });
              }
              
              return userAsync.when(
                loading: () => _buildLoadingWidget(),
                error: (error, stack) => _buildErrorWidget(error),
                data: (userData) => _buildContent(context, matchday, userData),
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'HOME',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => _showLogoutDialog(context),
          tooltip: 'Esci',
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, Matchday matchday, UserData userData) {
    final theme = Theme.of(context);
    final timeRemaining = _formatTimeRemaining(_remaining);
    final isExpired = _remaining.isNegative || _remaining == Duration.zero;

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(matchdayProvider);
        ref.refresh(userDataProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            _buildHeader(theme),
            const SizedBox(height: 16),
            _buildNextMatchInfo(theme, matchday.giornata),
            const SizedBox(height: 12),
            _buildCountdown(theme, timeRemaining, isExpired),
            const SizedBox(height: 32),
            _buildTeamSelectionButton(context, matchday, userData, isExpired),
            const SizedBox(height: 32),
            _buildJollyCard(context, theme, userData),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Text(
      AppConstants.homeTitle,
      textAlign: TextAlign.center,
      style: theme.textTheme.labelLarge!.copyWith(
        color: Colors.white70,
        letterSpacing: 2,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildNextMatchInfo(ThemeData theme, int giornata) {
    return Text(
      'Giornata $giornata\nSerie A',
      textAlign: TextAlign.center,
      style: theme.textTheme.headlineMedium!.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    );
  }

  Widget _buildCountdown(ThemeData theme, String timeRemaining, bool isExpired) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isExpired 
          ? Colors.red.withOpacity(0.2)
          : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isExpired ? 'SCADUTO' : timeRemaining,
        style: theme.textTheme.displaySmall!.copyWith(
          color: isExpired ? Colors.redAccent : Colors.white,
          fontWeight: FontWeight.bold,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildTeamSelectionButton(
    BuildContext context, 
    Matchday matchday, 
    UserData userData, 
    bool isExpired
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isExpired 
            ? Colors.grey 
            : const Color(0xFFE64A19),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isExpired ? 0 : 4,
        ),
        icon: Icon(isExpired ? Icons.lock : Icons.sports_soccer),
        onPressed: isExpired ? null : () => _showTeamPicker(context, matchday, userData),
        label: Text(
          isExpired ? 'TEMPO SCADUTO' : 'SCEGLI SQUADRA',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildJollyCard(BuildContext context, ThemeData theme, UserData userData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE64A19),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Jolly Vita',
                style: theme.textTheme.titleLarge!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Disponibili: ${userData.jollyLeft}/3',
            style: theme.textTheme.bodyLarge!.copyWith(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Salvati da un\'eliminazione con un Jolly Vita',
            style: theme.textTheme.bodyMedium!.copyWith(
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: userData.jollyLeft >= 3 
                  ? Colors.grey 
                  : const Color(0xFFE64A19),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.shopping_cart),
              onPressed: userData.jollyLeft >= 3 
                ? null 
                : () => _showPurchaseJollyDialog(context),
              label: Text(
                userData.jollyLeft >= 3 
                  ? 'LIMITE RAGGIUNTO' 
                  : 'ACQUISTA JOLLY (€5)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'Caricamento...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.white70,
          ),
          const SizedBox(height: 16),
          Text(
            'Errore: $error',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Usa il valore restituito per evitare il warning
              ref.refresh(matchdayProvider);
              ref.refresh(userDataProvider);
            },
            child: const Text('Riprova'),
          ),
        ],
      ),
    );
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.isNegative) return 'SCADUTO';
    
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (days > 0) {
      return '${days}g ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _showTeamPicker(BuildContext context, Matchday matchday, UserData userData) async {
    final team = await showDialog<String>(
      context: context,
      builder: (_) => TeamPickerDialog(
        allowedTeams: matchday.validTeams.isNotEmpty 
          ? matchday.validTeams 
          : AppConstants.mockTeams,
        blockedTeams: userData.teamsUsed,
      ),
    );
    
    if (team != null && mounted) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await ref.read(repoProvider).submitPick(
            user.uid,
            Pick(giornata: matchday.giornata, team: team),
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Scelta registrata: $team'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

   Future<void> _showLogoutDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma'),
        content: const Text('Sei sicuro di voler uscire?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Si', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    
    if (result == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _showPurchaseJollyDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acquista Jolly Vita'),
        content: const Text(
          'Un Jolly Vita costa 50 crediti e ti permette di salvarti da un\'eliminazione.\n\n'
          'Vuoi procedere con l\'acquisto?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementare logica di pagamento
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funzionalità in sviluppo'),
                ),
              );
            },
            child: const Text('Acquista'),
          ),
        ],
      ),
    );
  }
}

/// BottomNavigationBar ottimizzata
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Scegli',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profilo',
          ),
        ],
        onTap: (index) {
          if (index != currentIndex) {
            switch (index) {
              case 0:
                // Già in Home
                break;
              case 1:
                // Naviga a Stats
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StatsScreen(),
                  ),
                );
                break;
              case 2:
                // Naviga a Scegli
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ScegliScreen(),
                  ),
                );
                break;
              case 3:
                // Profile - da implementare
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sezione Profile in sviluppo'),
                    duration: Duration(seconds: 1),
                  ),
                );
                break;
            }
          }
        },
      ),
    );
  }
}