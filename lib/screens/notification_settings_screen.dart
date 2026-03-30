import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

/// Provider per lo stato delle notifiche
final notificationSettingsProvider = FutureProvider<NotificationSettings>((ref) async {
  final service = NotificationService();
  return NotificationSettings(
    matchStart: await service.matchStartNotificationsEnabled,
    matchEnd: await service.matchEndNotificationsEnabled,
    deadline: await service.deadlineRemindersEnabled,
    league: await service.leagueUpdatesEnabled,
  );
});

class NotificationSettings {
  final bool matchStart;
  final bool matchEnd;
  final bool deadline;
  final bool league;

  NotificationSettings({
    required this.matchStart,
    required this.matchEnd,
    required this.deadline,
    required this.league,
  });
}

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  bool _matchStart = true;
  bool _matchEnd = true;
  bool _deadline = true;
  bool _league = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final matchStart = await _notificationService.matchStartNotificationsEnabled;
    final matchEnd = await _notificationService.matchEndNotificationsEnabled;
    final deadline = await _notificationService.deadlineRemindersEnabled;
    final league = await _notificationService.leagueUpdatesEnabled;
    
    if (mounted) {
      setState(() {
        _matchStart = matchStart;
        _matchEnd = matchEnd;
        _deadline = deadline;
        _league = league;
        _isLoading = false;
      });
    }
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
          'NOTIFICHE',
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.accentOrange.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_active,
                                color: AppTheme.accentOrange,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Gestisci le tue notifiche',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scegli quali notifiche vuoi ricevere',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Sezione Partite
                      _buildSectionHeader('Partite', Icons.sports_soccer),
                      const SizedBox(height: 12),
                      
                      _buildNotificationSwitch(
                        title: 'Inizio partita',
                        subtitle: 'Ricevi una notifica quando inizia una partita della tua squadra',
                        icon: Icons.play_arrow,
                        value: _matchStart,
                        onChanged: (value) async {
                          setState(() => _matchStart = value);
                          await _notificationService.setMatchStartNotifications(value);
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildNotificationSwitch(
                        title: 'Risultato finale',
                        subtitle: 'Ricevi il risultato finale delle partite della tua squadra',
                        icon: Icons.flag,
                        value: _matchEnd,
                        onChanged: (value) async {
                          setState(() => _matchEnd = value);
                          await _notificationService.setMatchEndNotifications(value);
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Sezione Promemoria
                      _buildSectionHeader('Promemoria', Icons.alarm),
                      const SizedBox(height: 12),
                      
                      _buildNotificationSwitch(
                        title: 'Deadline scelta',
                        subtitle: 'Promemoria prima della scadenza per effettuare la scelta',
                        icon: Icons.timer,
                        value: _deadline,
                        onChanged: (value) async {
                          setState(() => _deadline = value);
                          await _notificationService.setDeadlineReminders(value);
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Sezione Lega
                      _buildSectionHeader('Lega', Icons.groups),
                      const SizedBox(height: 12),
                      
                      _buildNotificationSwitch(
                        title: 'Aggiornamenti lega',
                        subtitle: 'Notifiche su nuovi membri, eliminazioni e classifica',
                        icon: Icons.campaign,
                        value: _league,
                        onChanged: (value) async {
                          setState(() => _league = value);
                          await _notificationService.setLeagueUpdates(value);
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade300, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Le notifiche ti aiutano a non perdere mai una partita importante o una deadline.',
                                style: TextStyle(
                                  color: Colors.blue.shade300,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Pulsante test notifica
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _sendTestNotification,
                          icon: const Icon(Icons.send),
                          label: const Text('Invia notifica di test'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
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
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value 
              ? AppTheme.accentOrange.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: value 
                  ? AppTheme.accentOrange.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value ? AppTheme.accentOrange : Colors.grey,
              size: 24,
            ),
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
                const SizedBox(height: 4),
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
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      await _notificationService.showLeagueUpdateNotification(
        leagueName: 'Last Man Standing',
        message: 'Questa è una notifica di test! 🎉',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifica di test inviata!'),
            backgroundColor: Colors.green,
          ),
        );
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