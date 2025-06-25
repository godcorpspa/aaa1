import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';  
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'providers.dart';                     // i provider Riverpod
import 'widgets/team_picker_dialog.dart';    // dialog scelta squadra
import 'models/matchday.dart';
import 'models/user_data.dart';
import 'models/pick.dart';
import 'screens/welcome_screen.dart';        // nuova schermata iniziale
import 'firebase_options.dart';

const _mockTeams = [
  'Atalanta',
  'Bologna',
  'Cagliari',
  'Empoli',
  'Fiorentina',
  'Genoa',
  'Inter',
  'Juventus',
  'Lazio',
  'Lecce',
  'Milan',
  'Monza',
  'Napoli',
  'Roma',
  'Salernitana',
  'Sassuolo',
  'Torino',
  'Udinese',
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      title: 'Last Man Standing',
      home: const AuthGate(),
    );
  }
}

/// Decide quale schermata mostrare in base allo stato di autenticazione.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // caricamento iniziale
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // utente loggato → Home
        if (snapshot.hasData) {
          return const HomePage();
        }
        // altrimenti mostra la WelcomeScreen con i pulsanti “Accedi / Registrati”
        return const WelcomeScreen();
      },
    );
  }
}

///────────────────────────────────────────────────────────
/// HomePage – countdown + scelta squadra
///────────────────────────────────────────────────────────
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer(DateTime deadline) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final diff = deadline.difference(DateTime.now());
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchdayAsync = ref.watch(matchdayProvider);
    final userAsync     = ref.watch(userDataProvider);

    return Scaffold(
      extendBody: true,                    // gradient visibile sotto nav bar
      backgroundColor: Colors.transparent, // niente bianco di default
      bottomNavigationBar: const _BottomNav(currentIndex: 0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('HOME', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        constraints: const BoxConstraints.expand(),          // riempie tutto
        decoration: const BoxDecoration(gradient: AppTheme.gradient),
        child: SafeArea(
          child: matchdayAsync.when(
            loading: _loader,
            error: _err,
            data: (md) {
              if (_remaining == Duration.zero) _startTimer(md.deadline);
              return userAsync.when(
                loading: _loader,
                error: _err,
                data: (ud) => _buildContent(context, md, ud),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, Matchday md, UserData ud) {
    final d = _remaining;
    final countStr =
        '${d.inDays} g ${(d.inHours % 24).toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Text('LAST MAN  STANDING  -  SERIE A',
              style: Theme.of(ctx).textTheme.labelLarge!.copyWith(
                    color: Colors.white70,
                    letterSpacing: 2,
                  )),
          const SizedBox(height: 16),
          Text('Prossimo turno di\nSerie A',
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.headlineMedium!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 12),
          Text(countStr,
              style: Theme.of(ctx).textTheme.displaySmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 32),

          // pulsante scegli squadra
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE64A19),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: d.isNegative
                  ? null
                  : () async {
                      final team = await showDialog<String>(
                        context: ctx,
                        builder: (_) => TeamPickerDialog(
                          allowedTeams: md.validTeams.isNotEmpty? md.validTeams: _mockTeams, 
                          blockedTeams: ud.teamsUsed,
                        ),
                      );
                      if (team != null) {
                        ref.read(repoProvider).submitPick(
                          FirebaseAuth.instance.currentUser!.uid,
                          Pick(giornata: md.giornata, team: team),
                        );
                      }
                    },
              child: const Text('SCEGLI SQUADRA', style: TextStyle(fontSize: 18)),
            ),
          ),

          const SizedBox(height: 32),

          // Card Jolly
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.my_location, color: Colors.white, size: 28),
                    const SizedBox(width: 8),
                    Text('Jolly',
                        style: Theme.of(ctx).textTheme.titleLarge!.copyWith(
                              color: Colors.white,
                            )),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Disponibili: ${ud.jollyLeft}',
                    style: Theme.of(ctx).textTheme.bodyLarge!.copyWith(color: Colors.white)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE64A19),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {},
                    child: const Text('ACQUISTA JOLLY'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _loader() => const Center(child: CircularProgressIndicator(color: Colors.white));
  Widget _err(err, _) => Center(child: Text('Errore: $err', style: const TextStyle(color: Colors.white)));
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),  // <- velo nero 25 %
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: Colors
            .transparent,           // <- davvero trasparente (niente bianco)
        elevation: 0,                // senza ombra grigia
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Teams'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (idx) {
          // TODO: navigazione tra tab
        },
      ),
    );
  }
}

