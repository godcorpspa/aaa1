import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_repo.dart';
import 'services/football_data_service.dart'; // ← Nuovo import
import 'models/matchday.dart';
import 'models/user_data.dart';
import 'models/pick.dart';
import 'models/league_models.dart';

// === PROVIDER BASE ===

/// Provider per il repository Firestore (singleton)
final repoProvider = Provider<FirestoreRepo>((ref) {
  return FirestoreRepo();
});

/// Provider per il servizio Football-Data.org (REALE, non più mock)
final footballDataProvider = Provider<FootballDataService>((ref) {
  return FootballDataService();
});

/// Provider per lo stato di autenticazione
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provider per logging degli errori
final errorLoggerProvider = Provider<ErrorLogger>((ref) {
  return ErrorLogger();
});

// === PROVIDER LAST MAN STANDING ===

/// Provider per i dati della prossima giornata con gestione cache
final matchdayProvider = FutureProvider<Matchday>((ref) async {
  try {
    final repo = ref.read(repoProvider);
    return await repo.fetchNextMatchday();
  } catch (e, stack) {
    ref.read(errorLoggerProvider).logError('matchdayProvider', e, stack);
    rethrow;
  }
});

/// Provider per i dati utente con gestione errori migliorata
final userDataProvider = StreamProvider<UserData>((ref) {
  final authState = ref.watch(authProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) {
        throw const UserNotAuthenticatedException();
      }
      
      try {
        final repo = ref.read(repoProvider);
        return repo.streamUserData(user.uid);
      } catch (e, stack) {
        ref.read(errorLoggerProvider).logError('userDataProvider', e, stack);
        rethrow;
      }
    },
    loading: () => const Stream.empty(),
    error: (error, stack) => Stream.error(error, stack),
  );
});

/// Provider per gestione delle scelte utente
final userPicksProvider = StreamProvider.family<List<Pick>, String>((ref, userId) {
  try {
    final repo = ref.read(repoProvider);
    return repo.streamUserPicks(userId);
  } catch (e, stack) {
    ref.read(errorLoggerProvider).logError('userPicksProvider', e, stack);
    rethrow;
  }
});

// === PROVIDER SERIE A (con dati REALI da Football-Data.org) ===

/// Provider per la classifica Serie A (DATI REALI)
final serieAStandingsProvider = FutureProvider<List<LeagueStanding>>((ref) async {
  try {
    final service = ref.read(footballDataProvider);
    return await service.getStandings();
  } catch (e, stack) {
    ref.read(errorLoggerProvider).logError('serieAStandingsProvider', e, stack);
    rethrow;
  }
});

/// Provider per le partite live Serie A (DATI REALI)
final serieALiveMatchesProvider = FutureProvider<List<Match>>((ref) async {
  try {
    final service = ref.read(footballDataProvider);
    return await service.getLiveMatches();
  } catch (e, stack) {
    ref.read(errorLoggerProvider).logError('serieALiveMatchesProvider', e, stack);
    rethrow;
  }
});

/// Provider per la prossima partita Serie A (DATI REALI)
final nextSerieAMatchProvider = FutureProvider<Match?>((ref) async {
  try {
    final service = ref.read(footballDataProvider);
    return await service.getNextMatch();
  } catch (e, stack) {
    ref.read(errorLoggerProvider).logError('nextSerieAMatchProvider', e, stack);
    rethrow;
  }
});

/// Provider per i nomi delle squadre Serie A (DATI REALI)
final serieATeamNamesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final service = ref.read(footballDataProvider);
    return await service.getTeamNames();
  } catch (e, stack) {
    ref.read(errorLoggerProvider).logError('serieATeamNamesProvider', e, stack);
    rethrow;
  }
});

/// Provider per le partite di una giornata specifica Serie A (DATI REALI)
final serieAFixturesProvider = FutureProvider.family<List<Match>, int>((ref, round) async {
  try {
    final service = ref.read(footballDataProvider);
    return await service.getFixtures(round: round);
  } catch (e, stack) {
    ref.read(errorLoggerProvider).logError('serieAFixturesProvider', e, stack);
    rethrow;
  }
});

/// Provider per risultati recenti Serie A (DATI REALI)
final recentSerieAMatchesProvider = FutureProvider<List<Match>>((ref) async {
  try {
    final service = ref.read(footballDataProvider);
    return await service.getRecentResults(limit: 10);
  } catch (e, stack) {
    ref.read(errorLoggerProvider).logError('recentSerieAMatchesProvider', e, stack);
    rethrow;
  }
});

/// Provider per la giornata corrente (DATI REALI)
final currentMatchdayProvider = FutureProvider<int>((ref) async {
  try {
    final service = ref.read(footballDataProvider);
    return await service.getCurrentMatchday();
  } catch (e, stack) {
    ref.read(errorLoggerProvider).logError('currentMatchdayProvider', e, stack);
    rethrow;
  }
});

/// Provider per partite della prossima giornata (DATI REALI)
final nextMatchdayFixturesProvider = FutureProvider<List<Match>>((ref) async {
  try {
    final service = ref.read(footballDataProvider);
    // Prima ottieni la giornata corrente
    final currentMatchday = await service.getCurrentMatchday();
    // Poi carica le partite di quella giornata
    return await service.getFixtures(round: currentMatchday);
  } catch (e, stack) {
    ref.read(errorLoggerProvider).logError('nextMatchdayFixturesProvider', e, stack);
    rethrow;
  }
});

/// Provider per le prossime partite (DATI REALI)
final upcomingMatchesProvider = FutureProvider<List<Match>>((ref) async {
  try {
    final service = ref.read(footballDataProvider);
    return await service.getUpcomingMatches(limit: 10);
  } catch (e, stack) {
    ref.read(errorLoggerProvider).logError('upcomingMatchesProvider', e, stack);
    rethrow;
  }
});

/// Provider per tutte le squadre Serie A (DATI REALI)
final serieATeamsProvider = FutureProvider<List<Team>>((ref) async {
  try {
    final service = ref.read(footballDataProvider);
    return await service.getTeams();
  } catch (e, stack) {
    ref.read(errorLoggerProvider).logError('serieATeamsProvider', e, stack);
    rethrow;
  }
});

// === PROVIDER COMBINATI ===

/// Provider che combina partite live e countdown Serie A
final serieAMatchStatusProvider = FutureProvider<SerieAMatchStatus>((ref) async {
  final liveMatches = await ref.watch(serieALiveMatchesProvider.future);
  final nextMatch = await ref.watch(nextSerieAMatchProvider.future);
  
  return SerieAMatchStatus(
    liveMatches: liveMatches,
    nextMatch: nextMatch,
  );
});

/// Provider che combina lo stato di autenticazione e i dati utente
final authUserDataProvider = Provider<AsyncValue<(User?, UserData?)>>((ref) {
  final auth = ref.watch(authProvider);
  final userData = ref.watch(userDataProvider);
  
  return AsyncValue.data((
    auth.valueOrNull,
    userData.valueOrNull,
  ));
});

/// Provider per verificare se l'utente può fare una scelta
final canMakePickProvider = Provider<bool>((ref) {
  final matchday = ref.watch(matchdayProvider);
  final now = DateTime.now();
  
  return matchday.when(
    data: (md) => now.isBefore(md.deadline),
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider per calcolare il tempo rimanente
final timeRemainingProvider = StreamProvider<Duration>((ref) {
  final matchday = ref.watch(matchdayProvider);
  
  return matchday.when(
    data: (md) => Stream.periodic(
      const Duration(seconds: 1),
      (_) {
        final diff = md.deadline.difference(DateTime.now());
        return diff.isNegative ? Duration.zero : diff;
      },
    ),
    loading: () => Stream.value(Duration.zero),
    error: (_, __) => Stream.value(Duration.zero),
  );
});

// === PROVIDER PREFERENZE ===

/// Provider per le preferenze utente
final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  return UserPreferencesNotifier();
});

/// Provider per lo stato di connessione di rete
final connectivityProvider = StreamProvider<bool>((ref) {
  // TODO: Implementare controllo connettività reale
  return Stream.periodic(const Duration(seconds: 30), (_) => true);
});

// === CLASSI DI SUPPORTO ===

/// Classe per combinare stato partite Serie A
class SerieAMatchStatus {
  final List<Match> liveMatches;
  final Match? nextMatch;
  
  SerieAMatchStatus({
    required this.liveMatches,
    this.nextMatch,
  });
  
  bool get hasLiveMatches => liveMatches.isNotEmpty;
  
  Duration? get timeToNextMatch {
    if (nextMatch == null) return null;
    final now = DateTime.now();
    final diff = nextMatch!.date.difference(now);
    return diff.isNegative ? null : diff;
  }
}

/// Eccezione personalizzata per utente non autenticato
class UserNotAuthenticatedException implements Exception {
  const UserNotAuthenticatedException();
  
  @override
  String toString() => 'Utente non autenticato';
}

/// Classe per il logging degli errori
class ErrorLogger {
  void logError(String source, Object error, StackTrace? stack) {
    // In produzione, qui potresti inviare gli errori a un servizio come Crashlytics
    print('ERROR [$source]: $error');
    if (stack != null) {
      print('STACK: $stack');
    }
  }
  
  void logWarning(String source, String message) {
    print('WARNING [$source]: $message');
  }
  
  void logInfo(String source, String message) {
    print('INFO [$source]: $message');
  }
}

/// Modello per le preferenze utente
class UserPreferences {
  final bool notificationsEnabled;
  final String language;
  final bool darkMode;
  
  const UserPreferences({
    this.notificationsEnabled = true,
    this.language = 'it',
    this.darkMode = false,
  });
  
  UserPreferences copyWith({
    bool? notificationsEnabled,
    String? language,
    bool? darkMode,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

/// Notifier per le preferenze utente
class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier() : super(const UserPreferences());
  
  void setNotifications(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
  }
  
  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }
  
  void setDarkMode(bool darkMode) {
    state = state.copyWith(darkMode: darkMode);
  }
}