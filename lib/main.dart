import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';  
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:last_man_standing/providers/league_providers.dart' show userHasLeaguesProvider, currentUserLeaguesProvider, userLeaguesProvider;
import '../theme/app_theme.dart';
import 'providers.dart';
import 'shared_providers.dart'; // ← AGGIUNTO
import 'widgets/gradient_background.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_layout.dart';
import 'screens/join_league_screen.dart'; // ← AGGIUNTO
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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listener per pulire cache quando cambia utente
    ref.listen(authProvider, (previous, next) {
      final previousUser = previous?.valueOrNull;
      final currentUser = next.valueOrNull;
      
      // Se l'utente è cambiato (login/logout)
      if (previousUser?.uid != currentUser?.uid) {
        print('🔄 Utente cambiato da ${previousUser?.uid} a ${currentUser?.uid}');
        
        // Invalida tutti i provider user-specific
        ref.invalidate(userHasLeaguesProvider);
        ref.invalidate(currentUserLeaguesProvider);
        
        // Se c'era un utente precedente, invalida anche i suoi provider
        if (previousUser != null) {
          ref.invalidate(userLeaguesProvider(previousUser.uid));
        }
      }
    });

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
      theme: AppTheme.theme,
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
    final hasLeagues = ref.watch(hasLeaguesProvider);
    
    return authState.when(
      loading: () => Scaffold(
        body: GradientBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'Caricamento...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: GradientBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.white70),
                const SizedBox(height: 16),
                const Text(
                  'Errore di connessione',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.refresh(authProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Riprova'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (user) {
        // Debug print per vedere cosa sta succedendo
        print('🔍 AuthGate - User: ${user?.email} (${user?.uid})');
        print('🔍 AuthGate - HasLeagues: $hasLeagues');
        
        // Se l'utente non è autenticato, mostra welcome screen
        if (user == null) {
          return const WelcomeScreen();
        }
        
        // Se l'utente è autenticato ma non ha leghe, mostra JoinLeagueScreen
        if (!hasLeagues) {
          return const JoinLeagueScreen();
        }
        
        // Se l'utente è autenticato e ha leghe, mostra MainLayout
        return const MainLayout();
      },
    );
  }
}