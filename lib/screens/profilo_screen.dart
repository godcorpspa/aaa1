import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers.dart';
import '../theme/app_theme.dart';

class ProfiloScreen extends ConsumerWidget {
  const ProfiloScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final userDataAsync = ref.watch(userDataProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'PROFILO',
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
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showSettingsDialog(context),
            tooltip: 'Impostazioni',
          ),
        ],
      ),
      body: SafeArea(
        child: userDataAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (error, stack) => _buildErrorWidget(context, error),
          data: (userData) => _buildContent(context, user, userData),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, User? user, dynamic userData) {
    if (user == null) {
      return _buildNotAuthenticatedView();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Avatar e info utente
          _buildUserHeader(user, userData),
          
          const SizedBox(height: 32),
          
          // Statistiche dettagliate
          _buildDetailedStats(userData),
          
          const SizedBox(height: 32),
          
          // Azioni profilo
          _buildProfileActions(context),
          
          const SizedBox(height: 32),
          
          // Info app
          _buildAppInfo(context),
        ],
      ),
    );
  }

  Widget _buildUserHeader(User user, dynamic userData) {
    final displayName = user.displayName ?? userData?.displayName ?? 'Utente';
    final email = user.email ?? '';
    final isActive = userData?.isActive ?? true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.accentOrange : Colors.grey,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: (isActive ? AppTheme.accentOrange : Colors.grey).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: user.photoURL != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      user.photoURL!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          displayName.isNotEmpty 
                            ? displayName.substring(0, 1).toUpperCase()
                            : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    displayName.isNotEmpty 
                      ? displayName.substring(0, 1).toUpperCase()
                      : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Nome utente
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Email
          Text(
            email,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive 
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive 
                  ? Colors.green.withOpacity(0.5)
                  : Colors.red.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? Icons.sports_soccer : Icons.cancel,
                  color: isActive ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isActive ? 'GIOCATORE ATTIVO' : 'ELIMINATO',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(dynamic userData) {
    final jollyLeft = userData?.jollyLeft ?? 0;
    final teamsUsed = userData?.teamsUsed ?? <String>[];
    final currentStreak = userData?.currentStreak ?? 0;
    final totalWins = userData?.totalWins ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'STATISTICHE DETTAGLIATE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Prima riga
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Jolly rimasti',
                  '$jollyLeft/3',
                  Icons.favorite,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Squadre usate',
                  '${teamsUsed.length}/20',
                  Icons.sports_soccer,
                  Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Seconda riga
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Streak corrente',
                  '$currentStreak',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Vittorie totali',
                  '$totalWins',
                  Icons.emoji_events,
                  Colors.amber,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Squadre utilizzate (se presenti)
          if (teamsUsed.isNotEmpty) ...[
            const Text(
              'Squadre già utilizzate:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (teamsUsed as List<dynamic>).map<Widget>((team) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.accentOrange.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  team.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
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

  Widget _buildProfileActions(BuildContext context) {
    return Column(
      children: [
        // Modifica profilo
        _buildActionCard(
          title: 'Modifica Profilo',
          subtitle: 'Cambia nome utente e foto',
          icon: Icons.edit,
          color: AppTheme.accentOrange,
          onTap: () => _showEditProfileDialog(context),
        ),
        
        const SizedBox(height: 12),
        
        // Impostazioni privacy
        _buildActionCard(
          title: 'Privacy e Sicurezza',
          subtitle: 'Gestisci le tue impostazioni',
          icon: Icons.security,
          color: Colors.blue,
          onTap: () => _showPrivacyDialog(context),
        ),
        
        const SizedBox(height: 12),
        
        // Logout
        _buildActionCard(
          title: 'Esci',
          subtitle: 'Disconnetti dal tuo account',
          icon: Icons.logout,
          color: Colors.red,
          onTap: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'INFORMAZIONI APP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow('Versione', '1.0.0'),
          _buildInfoRow('Sviluppatore', 'Last Man Standing Team'),
          _buildInfoRow('Licenza', 'MIT License'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotAuthenticatedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.login,
            size: 64,
            color: Colors.white70,
          ),
          const SizedBox(height: 24),
          const Text(
            'Accesso richiesto',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Devi essere autenticato per\naccedere al profilo',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.white70,
            ),
            const SizedBox(height: 16),
            const Text(
              'Errore nel caricamento',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impossibile caricare i dati del profilo',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Dialog functions
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Impostazioni'),
        content: const Text('Funzionalità in sviluppo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica Profilo'),
        content: const Text('Funzionalità in sviluppo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy e Sicurezza'),
        content: const Text('Funzionalità in sviluppo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma'),
        content: const Text('Sei sicuro di voler uscire?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
            child: const Text('Esci'),
          ),
        ],
      ),
    );
  }
}