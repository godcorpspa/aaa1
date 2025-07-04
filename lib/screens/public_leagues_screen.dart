import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_man_standing/providers/league_providers.dart';
import '../widgets/gradient_background.dart';
import '../theme/app_theme.dart';
import '../models/league_models.dart';
import '../services/league_service.dart';

class PublicLeaguesScreen extends ConsumerWidget {
  const PublicLeaguesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Recupera le leghe pubbliche dal provider
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
          'Leghe pubbliche',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: publicLeaguesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, stack) => _buildErrorWidget(context, ref, error),
            data: (leagues) => _buildContent(context, ref, leagues),
          ),
        ),
      ),
    );
  }

  /// Contenuto principale – lista leghe
  Widget _buildContent(BuildContext context, WidgetRef ref, List<LastManStandingLeague> leagues) {
    if (leagues.isEmpty) {
      return const Center(
        child: Text(
          'Nessuna lega pubblica disponibile al momento.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

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
              // Chiede nuovamente i dati al provider
              ref.invalidate(publicLeaguesProvider(null));
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: leagues.length,
              itemBuilder: (context, index) =>
                  _buildLeagueCard(context, ref, leagues[index]),
            ),
          ),
        ),
      ],
    );
  }

  /// Card per singola lega
  Widget _buildLeagueCard(BuildContext context, WidgetRef ref, LastManStandingLeague league) {
    final bool isFull = league.currentParticipants >= league.maxParticipants;

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
                    color: isFull
                        ? Colors.red.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFull
                          ? Colors.red.withOpacity(0.5)
                          : Colors.green.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    isFull ? 'PIENA' : 'APERTA',
                    style: TextStyle(
                      color: isFull ? Colors.red : Colors.green,
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
                  value:
                      '${league.currentParticipants}/${league.maxParticipants}',
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

            // Pulsante entra
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isFull
                    ? null
                    : () {
                        _joinLeague(context, ref, league);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isFull ? Colors.grey : AppTheme.accentOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Entra',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Azione di join alla lega
  Future<void> _joinLeague(BuildContext context, WidgetRef ref, LastManStandingLeague league) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Servizio
    final leagueService = ref.read(leagueServiceProvider);

    // Mostra loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await leagueService.joinLeague(leagueId: league.id);
      navigator.pop(); // chiude il dialog
      messenger.showSnackBar(
        const SnackBar(content: Text('Ti sei unito alla lega con successo!')),
      );
      // aggiorna i provider interessati
      ref.invalidate(currentUserLeaguesProvider);
      ref.invalidate(publicLeaguesProvider(null));
      navigator.pop(); // torna alla schermata precedente
    } on LeagueException catch (e) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Si è verificato un errore imprevisto.')),
      );
    }
  }

  /// Widget singolo info (etichetta + valore)
  Widget _buildInfoItem({required IconData icon, required String label, required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Widget di errore
  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Errore nel caricamento delle leghe pubbliche.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(publicLeaguesProvider(null));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Riprova'),
          )
        ],
      ),
    );
  }
}