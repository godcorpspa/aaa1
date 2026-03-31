import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:last_man_standing/providers/league_providers.dart'
    show userHasLeaguesProvider, currentUserLeaguesProvider, userLeaguesProvider;
import 'theme/app_theme.dart';
import 'providers.dart';
import 'shared_providers.dart';
import 'widgets/gradient_background.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_layout.dart';
import 'screens/join_league_screen.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inizializza handler per messaggi in background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Inizializza il servizio notifiche (non bloccante)
  NotificationService().initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authProvider, (previous, next) {
      final prevUid = previous?.valueOrNull?.uid;
      final currUid = next.valueOrNull?.uid;
      if (prevUid != currUid) {
        ref.invalidate(userHasLeaguesProvider);
        ref.invalidate(currentUserLeaguesProvider);
        if (prevUid != null) {
          ref.invalidate(userLeaguesProvider(prevUid));
        }

        if (currUid != null) {
          NotificationService().subscribeToTopic('all_users');
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
      title: 'Last Man Standing',
      theme: AppTheme.theme,
      home: const AuthGate(),
    );
  }
}

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
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sports_soccer,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'Caricamento...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        body: GradientBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.7)),
                  const SizedBox(height: 16),
                  const Text(
                    'Errore di connessione',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(authProvider),
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      data: (user) {
        if (user == null) return const WelcomeScreen();
        if (!hasLeagues) return const JoinLeagueScreen();
        return const MainLayout();
      },
    );
  }
}
