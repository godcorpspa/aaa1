import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servizio per gestire le notifiche push
/// Supporta notifiche per:
/// - Inizio partita della squadra scelta
/// - Risultato finale
/// - Promemoria deadline scelta
/// - Aggiornamenti della lega
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  String? _fcmToken;

  // Chiavi per SharedPreferences
  static const String _keyMatchStartNotifications = 'notif_match_start';
  static const String _keyMatchEndNotifications = 'notif_match_end';
  static const String _keyDeadlineReminders = 'notif_deadline';
  static const String _keyLeagueUpdates = 'notif_league';

  /// Inizializza il servizio di notifiche
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Richiedi permessi
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      
      // Inizializza notifiche locali
      await _initializeLocalNotifications();
      
      // Ottieni token FCM
      _fcmToken = await _fcm.getToken();
      print('🔔 FCM Token: $_fcmToken');
      
      // Gestisci token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveTokenToServer(newToken);
      });
      
      // Gestisci messaggi in foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Gestisci tap su notifica quando app è in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      // Controlla se l'app è stata aperta da una notifica
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
      
      _isInitialized = true;
      print('✅ NotificationService inizializzato');
    } else {
      print('❌ Permessi notifiche negati');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Crea canali di notifica per Android
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'match_start',
        'Inizio Partite',
        description: 'Notifiche quando inizia una partita della tua squadra',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'match_end',
        'Risultati Partite',
        description: 'Notifiche con il risultato finale delle partite',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'deadline',
        'Promemoria Deadline',
        description: 'Promemoria per effettuare la scelta prima della deadline',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'league',
        'Aggiornamenti Lega',
        description: 'Aggiornamenti sulla tua lega',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    ];

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      for (final channel in channels) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }
  }

  /// Gestisce i messaggi ricevuti in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('📩 Messaggio in foreground: ${message.notification?.title}');
    
    final notification = message.notification;
    final data = message.data;
    
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'Last Man Standing',
        body: notification.body ?? '',
        channelId: data['channel'] ?? 'league',
        payload: jsonEncode(data),
      );
    }
  }

  /// Gestisce il tap su una notifica
  void _handleNotificationTap(RemoteMessage message) {
    print('👆 Tap su notifica: ${message.data}');
    // TODO: Navigare alla schermata appropriata in base ai dati
    _processNotificationAction(message.data);
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _processNotificationAction(data);
      } catch (e) {
        print('Errore nel parsing del payload: $e');
      }
    }
  }

  void _processNotificationAction(Map<String, dynamic> data) {
    final action = data['action'];
    
    switch (action) {
      case 'open_match':
        // TODO: Navigare alla schermata partita
        break;
      case 'open_pick':
        // TODO: Navigare alla schermata scelta
        break;
      case 'open_league':
        // TODO: Navigare alla schermata lega
        break;
      default:
        // Apri la home
        break;
    }
  }

  /// Mostra una notifica locale
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String channelId = 'league',
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: 'Notifiche Last Man Standing',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'match_start':
        return 'Inizio Partite';
      case 'match_end':
        return 'Risultati Partite';
      case 'deadline':
        return 'Promemoria Deadline';
      default:
        return 'Aggiornamenti Lega';
    }
  }

  /// Iscriviti a un topic (es. squadra, lega)
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    print('📬 Iscritto al topic: $topic');
  }

  /// Disiscriviti da un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    print('📭 Disiscritto dal topic: $topic');
  }

  /// Iscriviti alle notifiche per una squadra specifica
  Future<void> subscribeToTeam(String teamName) async {
    final topic = 'team_${_sanitizeTopicName(teamName)}';
    await subscribeToTopic(topic);
  }

  /// Disiscriviti dalle notifiche per una squadra
  Future<void> unsubscribeFromTeam(String teamName) async {
    final topic = 'team_${_sanitizeTopicName(teamName)}';
    await unsubscribeFromTopic(topic);
  }

  /// Iscriviti alle notifiche per una lega
  Future<void> subscribeToLeague(String leagueId) async {
    await subscribeToTopic('league_$leagueId');
  }

  /// Disiscriviti dalle notifiche per una lega
  Future<void> unsubscribeFromLeague(String leagueId) async {
    await unsubscribeFromTopic('league_$leagueId');
  }

  String _sanitizeTopicName(String name) {
    return name
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  /// Salva il token FCM sul server
  Future<void> _saveTokenToServer(String token) async {
    // TODO: Implementare chiamata API per salvare il token
    print('💾 Token da salvare sul server: $token');
  }

  /// Ottieni il token FCM corrente
  String? get fcmToken => _fcmToken;

  // === GESTIONE PREFERENZE NOTIFICHE ===

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  /// Abilita/disabilita notifiche inizio partita
  Future<void> setMatchStartNotifications(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyMatchStartNotifications, enabled);
    
    if (enabled) {
      await subscribeToTopic('match_start_all');
    } else {
      await unsubscribeFromTopic('match_start_all');
    }
  }

  Future<bool> get matchStartNotificationsEnabled async {
    final prefs = await _prefs;
    return prefs.getBool(_keyMatchStartNotifications) ?? true;
  }

  /// Abilita/disabilita notifiche fine partita
  Future<void> setMatchEndNotifications(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyMatchEndNotifications, enabled);
    
    if (enabled) {
      await subscribeToTopic('match_end_all');
    } else {
      await unsubscribeFromTopic('match_end_all');
    }
  }

  Future<bool> get matchEndNotificationsEnabled async {
    final prefs = await _prefs;
    return prefs.getBool(_keyMatchEndNotifications) ?? true;
  }

  /// Abilita/disabilita promemoria deadline
  Future<void> setDeadlineReminders(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyDeadlineReminders, enabled);
    
    if (enabled) {
      await subscribeToTopic('deadline_reminders');
    } else {
      await unsubscribeFromTopic('deadline_reminders');
    }
  }

  Future<bool> get deadlineRemindersEnabled async {
    final prefs = await _prefs;
    return prefs.getBool(_keyDeadlineReminders) ?? true;
  }

  /// Abilita/disabilita aggiornamenti lega
  Future<void> setLeagueUpdates(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyLeagueUpdates, enabled);
  }

  Future<bool> get leagueUpdatesEnabled async {
    final prefs = await _prefs;
    return prefs.getBool(_keyLeagueUpdates) ?? true;
  }

  // === NOTIFICHE MANUALI (per testing o trigger locali) ===

  /// Mostra notifica inizio partita
  Future<void> showMatchStartNotification({
    required String homeTeam,
    required String awayTeam,
    String? yourTeam,
  }) async {
    final isYourMatch = yourTeam != null && 
        (homeTeam.toLowerCase().contains(yourTeam.toLowerCase()) ||
         awayTeam.toLowerCase().contains(yourTeam.toLowerCase()));

    await _showLocalNotification(
      title: isYourMatch ? '⚽ La tua squadra sta giocando!' : '⚽ Partita iniziata',
      body: '$homeTeam vs $awayTeam è appena iniziata',
      channelId: 'match_start',
      payload: jsonEncode({
        'action': 'open_match',
        'home_team': homeTeam,
        'away_team': awayTeam,
      }),
    );
  }

  /// Mostra notifica risultato partita
  Future<void> showMatchEndNotification({
    required String homeTeam,
    required String awayTeam,
    required int homeScore,
    required int awayScore,
    String? yourTeam,
  }) async {
    final isYourMatch = yourTeam != null && 
        (homeTeam.toLowerCase().contains(yourTeam.toLowerCase()) ||
         awayTeam.toLowerCase().contains(yourTeam.toLowerCase()));

    String resultEmoji;
    String resultText;
    
    if (yourTeam != null) {
      final yourTeamIsHome = homeTeam.toLowerCase().contains(yourTeam.toLowerCase());
      final yourScore = yourTeamIsHome ? homeScore : awayScore;
      final theirScore = yourTeamIsHome ? awayScore : homeScore;
      
      if (yourScore > theirScore) {
        resultEmoji = '🎉';
        resultText = 'VITTORIA! Sei salvo!';
      } else if (yourScore < theirScore) {
        resultEmoji = '😢';
        resultText = 'Sconfitta... Usa un Jolly!';
      } else {
        resultEmoji = '😰';
        resultText = 'Pareggio... Usa un Jolly!';
      }
    } else {
      resultEmoji = '🏁';
      resultText = 'Partita terminata';
    }

    await _showLocalNotification(
      title: '$resultEmoji $resultText',
      body: '$homeTeam $homeScore - $awayScore $awayTeam',
      channelId: 'match_end',
      payload: jsonEncode({
        'action': 'open_match',
        'home_team': homeTeam,
        'away_team': awayTeam,
        'home_score': homeScore,
        'away_score': awayScore,
      }),
    );
  }

  /// Mostra promemoria deadline
  Future<void> showDeadlineReminder({
    required int giornata,
    required Duration timeRemaining,
  }) async {
    String timeText;
    if (timeRemaining.inHours > 0) {
      timeText = '${timeRemaining.inHours} ore';
    } else {
      timeText = '${timeRemaining.inMinutes} minuti';
    }

    await _showLocalNotification(
      title: '⏰ Deadline in arrivo!',
      body: 'Hai ancora $timeText per scegliere la tua squadra per la giornata $giornata',
      channelId: 'deadline',
      payload: jsonEncode({
        'action': 'open_pick',
        'giornata': giornata,
      }),
    );
  }

  /// Mostra notifica aggiornamento lega
  Future<void> showLeagueUpdateNotification({
    required String leagueName,
    required String message,
    String? leagueId,
  }) async {
    await _showLocalNotification(
      title: '📢 $leagueName',
      body: message,
      channelId: 'league',
      payload: jsonEncode({
        'action': 'open_league',
        'league_id': leagueId,
      }),
    );
  }

  /// Cancella tutte le notifiche
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}

/// Handler per messaggi in background (deve essere top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Messaggio in background: ${message.messageId}');
  // Le notifiche vengono gestite automaticamente dal sistema
}