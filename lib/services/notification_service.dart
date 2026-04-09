import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Servizio per gestire le notifiche push
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  static const String _keyMatchStartNotifications = 'notif_match_start';
  static const String _keyMatchEndNotifications = 'notif_match_end';
  static const String _keyDeadlineReminders = 'notif_deadline';
  static const String _keyLeagueUpdates = 'notif_league';

  /// Inizializza il servizio di notifiche
  Future<void> initialize() async {
    if (_isInitialized) return;

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

      await _initializeLocalNotifications();

      _fcmToken = await _fcm.getToken();

      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveTokenToServer(newToken);
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _isInitialized = true;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    // Initialize timezone data so we can schedule notifications with
    // tz.TZDateTime (required by flutter_local_notifications >= 10).
    tzdata.initializeTimeZones();

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

  void _handleForegroundMessage(RemoteMessage message) {
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

  void _handleNotificationTap(RemoteMessage message) {
    _processNotificationAction(message.data);
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _processNotificationAction(data);
      } catch (e) {
        debugPrint('Errore nel parsing del payload: $e');
      }
    }
  }

  void _processNotificationAction(Map<String, dynamic> data) {
    // TODO: Implementare navigazione basata su data['action']
  }

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

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  Future<void> subscribeToTeam(String teamName) async {
    final topic = 'team_${_sanitizeTopicName(teamName)}';
    await subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTeam(String teamName) async {
    final topic = 'team_${_sanitizeTopicName(teamName)}';
    await unsubscribeFromTopic(topic);
  }

  Future<void> subscribeToLeague(String leagueId) async {
    await subscribeToTopic('league_$leagueId');
  }

  Future<void> unsubscribeFromLeague(String leagueId) async {
    await unsubscribeFromTopic('league_$leagueId');
  }

  String _sanitizeTopicName(String name) {
    return name
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  Future<void> _saveTokenToServer(String token) async {
    // TODO: Implementare chiamata API per salvare il token su Firestore
  }

  String? get fcmToken => _fcmToken;

  // === GESTIONE PREFERENZE NOTIFICHE ===

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

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

  Future<void> setLeagueUpdates(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyLeagueUpdates, enabled);
  }

  Future<bool> get leagueUpdatesEnabled async {
    final prefs = await _prefs;
    return prefs.getBool(_keyLeagueUpdates) ?? true;
  }

  // === NOTIFICHE MANUALI ===

  Future<void> showMatchStartNotification({
    required String homeTeam,
    required String awayTeam,
    String? yourTeam,
  }) async {
    final isYourMatch = yourTeam != null &&
        (homeTeam.toLowerCase().contains(yourTeam.toLowerCase()) ||
         awayTeam.toLowerCase().contains(yourTeam.toLowerCase()));

    await _showLocalNotification(
      title: isYourMatch ? 'La tua squadra sta giocando!' : 'Partita iniziata',
      body: '$homeTeam vs $awayTeam e\' appena iniziata',
      channelId: 'match_start',
      payload: jsonEncode({
        'action': 'open_match',
        'home_team': homeTeam,
        'away_team': awayTeam,
      }),
    );
  }

  Future<void> showMatchEndNotification({
    required String homeTeam,
    required String awayTeam,
    required int homeScore,
    required int awayScore,
    String? yourTeam,
  }) async {
    String resultText;

    if (yourTeam != null) {
      final yourTeamIsHome = homeTeam.toLowerCase().contains(yourTeam.toLowerCase());
      final yourScore = yourTeamIsHome ? homeScore : awayScore;
      final theirScore = yourTeamIsHome ? awayScore : homeScore;

      if (yourScore > theirScore) {
        resultText = 'VITTORIA! Sei salvo!';
      } else if (yourScore < theirScore) {
        resultText = 'Sconfitta... Usa un Gold Ticket!';
      } else {
        resultText = 'Pareggio... Usa un Gold Ticket!';
      }
    } else {
      resultText = 'Partita terminata';
    }

    await _showLocalNotification(
      title: resultText,
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
      title: 'Deadline in arrivo!',
      body: 'Hai ancora $timeText per scegliere la tua squadra per la giornata $giornata',
      channelId: 'deadline',
      payload: jsonEncode({
        'action': 'open_pick',
        'giornata': giornata,
      }),
    );
  }

  /// Notification id used for the scheduled deadline reminder.
  /// It is stable, so re-scheduling automatically cancels the previous one.
  static const int _scheduledDeadlineId = 90001;

  /// Schedules a local notification exactly 30 minutes before the pick
  /// deadline for [giornata]. If the target instant is already in the past
  /// the previous scheduled notification is just cancelled.
  ///
  /// Safe to call multiple times — it always replaces the previous schedule.
  Future<void> scheduleDeadlineReminder30MinBefore({
    required int giornata,
    required DateTime deadline,
  }) async {
    if (!_isInitialized) {
      try {
        await _initializeLocalNotifications();
      } catch (_) {
        return;
      }
    }

    // Cancel any previous scheduled reminder (even if deadline has moved).
    await _localNotifications.cancel(_scheduledDeadlineId);

    final fireAt = deadline.subtract(const Duration(minutes: 30));
    if (fireAt.isBefore(DateTime.now())) {
      return; // Too late to schedule.
    }

    final tzFireAt = tz.TZDateTime.from(fireAt, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'deadline',
      'Promemoria Deadline',
      channelDescription:
          'Promemoria per effettuare la scelta prima della deadline',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.zonedSchedule(
        _scheduledDeadlineId,
        'Scegli la tua squadra!',
        'Mancano 30 minuti alla scadenza della giornata $giornata',
        tzFireAt,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode({
          'action': 'open_pick',
          'giornata': giornata,
        }),
      );
    } catch (e) {
      debugPrint('Errore nello scheduling del promemoria deadline: $e');
    }
  }

  /// Cancels any previously scheduled deadline reminder.
  Future<void> cancelScheduledDeadlineReminder() async {
    try {
      await _localNotifications.cancel(_scheduledDeadlineId);
    } catch (_) {}
  }

  Future<void> showLeagueUpdateNotification({
    required String leagueName,
    required String message,
    String? leagueId,
  }) async {
    await _showLocalNotification(
      title: leagueName,
      body: message,
      channelId: 'league',
      payload: jsonEncode({
        'action': 'open_league',
        'league_id': leagueId,
      }),
    );
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}

/// Handler per messaggi in background (deve essere top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Le notifiche vengono gestite automaticamente dal sistema
}
