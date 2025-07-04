import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_man_standing/providers/league_providers.dart';
import '../widgets/gradient_background.dart';
import '../theme/app_theme.dart';
import '../models/league_models.dart';

class PublicLeaguesScreen extends ConsumerWidget {
  const PublicLeaguesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usa il provider per ottenere le leghe pubbliche dal database
    final publicLeaguesAsync = ref.watch(publicLeaguesProvider(null));

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
          'Leghe Pubbliche',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.invalidate(publicLeaguesProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aggiornamento completato')),
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: publicLeaguesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, stack) => _buildErrorWidget(context, ref, error),
            data: (leagues) => _buildContent(context, ref, leagues.cast<UserLeague>()),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<UserLeague> leagues) {
    return Column(
      children: [
        const SizedBox(height: 20),
        
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Scegli una lega pubblica e inizia a giocare!',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Lista leghe
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // Placeholder per refresh
              await Future.delayed(const Duration(seconds: 1));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lista aggiornata!')),
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: leagues.length,
              itemBuilder: (context, index) => _buildLeagueCard(
                context, 
                ref, 
                leagues[index]
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueCard(BuildContext context, WidgetRef ref, UserLeague league) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nome e status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        league.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        league.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: league.isFull 
                      ? Colors.red.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: league.isFull 
                        ? Colors.red.withOpacity(0.5)
                        : Colors.green.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    league.isFull ? 'PIENA' : 'APERTA',
                    style: TextStyle(
                      color: league.isFull ? Colors.red : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informazioni lega
            Row(
              children: [
                _buildInfoItem(
                  icon: Icons.people,
                  label: 'Partecipanti',
                  value: '${league.currentParticipants}/${league.maxParticipants}',
                ),
                const SizedBox(width: 20),
                _buildInfoItem(
                  icon: Icons.person,
                  label: 'Creatore',
                  value: league.creatorName,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Creata',
                  value: _formatDate(league.createdAt),
                ),
                const SizedBox(width: 20),
                _buildInfoItem(
                  icon: league.isPrivate ? Icons.lock : Icons.public,
                  label: 'Tipo',
                  value: league.isPrivate ? 'Privata' : 'Pubblica',
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Pulsante unisciti
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: league.isFull ? null : () => _joinLeague(context, ref, league),
                style: ElevatedButton.styleFrom(
                  backgroundColor: league.isFull 
                    ? Colors.grey 
                    : AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: league.isFull ? 0 : 4,
                ),
                child: Text(
                  league.isFull ? 'LEGA PIENA' : 'UNISCITI ALLA LEGA',
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
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _joinLeague(BuildContext context, WidgetRef ref, UserLeague league) async {
    // Mostra dialog di conferma
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma'),
        content: Text('Vuoi unirti alla lega "${league.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unisciti'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Mostra loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Unendosi alla lega...'),
            ],
          ),
        ),
      );

      // Simula chiamata API
      await ref.read(leagueServiceProvider).joinLeague(
        leagueId: league.id,
        password: null, // o richiedi password se necessario
      );

      if (context.mounted) {
      // Chiudi il loading dialog
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        ref.invalidate(userLeaguesProvider(user.uid));
        ref.invalidate(currentUserLeaguesProvider);
        ref.invalidate(userHasLeaguesProvider);
      }
      Navigator.pop(context);
      
      // Mostra successo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ti sei unito alla lega "${league.name}" con successo!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Forza un refresh del provider delle leghe
      ref.invalidate(userLeaguesProvider);
      
      // Attendi brevemente che lo stato si aggiorni
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Torna alla schermata principale
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  } catch (e) {
    if (context.mounted) {
      // Chiudi il loading dialog
      Navigator.pop(context);
      
      // Mostra errore
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

_buildErrorWidget(BuildContext context, WidgetRef ref, Object error) {
  print('Errore ciao');
}