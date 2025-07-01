import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../providers.dart';
import '../models/matchday.dart';
import '../models/user_data.dart';
import '../theme/app_theme.dart';

/// HomePage ottimizzata senza bottom navigation (ora gestita dal MainLayout)
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
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(context),
      body: Container(
        constraints: const BoxConstraints.expand(),
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
      automaticallyImplyLeading: false, // Rimuove il back button
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
            _buildQuickStats(context, userData),
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
      'LAST MAN STANDING - SERIE A',
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

  Widget _buildQuickStats(BuildContext context, UserData userData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                  color: AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Le tue statistiche',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Statistiche in griglia
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Squadre usate',
                  '${userData.teamsUsed.length}',
                  Icons.sports_soccer,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Vittorie totali',
                  '${userData.totalWins}',
                  Icons.emoji_events,
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Streak corrente',
                  '${userData.currentStreak}',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Status',
                  userData.isActive ? 'ATTIVO' : 'ELIMINATO',
                  userData.isActive ? Icons.check_circle : Icons.cancel,
                  userData.isActive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
                  : 'ACQUISTA JOLLY (50 Crediti)',
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