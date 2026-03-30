import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_repo.dart';
import 'services/football_data_service.dart';
import 'models/matchday.dart';
import 'models/user_data.dart';
import 'models/pick.dart';
import 'models/league_models.dart';

// === BASE PROVIDERS ===

final repoProvider = Provider<FirestoreRepo>((ref) => FirestoreRepo());

/// Provider per il servizio Football-Data.org (dati reali Serie A)
final footballDataProvider = Provider<FootballDataService>((ref) {
  return FootballDataService();
});

final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// === LAST MAN STANDING PROVIDERS ===

final matchdayProvider = FutureProvider<Matchday>((ref) async {
  final repo = ref.read(repoProvider);
  return await repo.fetchNextMatchday();
});

final userDataProvider = StreamProvider<UserData>((ref) {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (user) {
      if (user == null) throw const UserNotAuthenticatedException();
      final repo = ref.read(repoProvider);
      return repo.streamUserData(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (error, stack) => Stream.error(error, stack),
  );
});

final userPicksProvider =
    StreamProvider.family<List<Pick>, String>((ref, userId) {
  final repo = ref.read(repoProvider);
  return repo.streamUserPicks(userId);
});

// === SERIE A PROVIDERS (dati reali da Football-Data.org) ===

final serieAStandingsProvider =
    FutureProvider<List<LeagueStanding>>((ref) async {
  final service = ref.read(footballDataProvider);
  return await service.getStandings();
});

final serieALiveMatchesProvider = FutureProvider<List<Match>>((ref) async {
  final service = ref.read(footballDataProvider);
  return await service.getLiveMatches();
});

final nextSerieAMatchProvider = FutureProvider<Match?>((ref) async {
  final service = ref.read(footballDataProvider);
  return await service.getNextMatch();
});

final serieATeamNamesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(footballDataProvider);
  return await service.getTeamNames();
});

final serieAFixturesProvider =
    FutureProvider.family<List<Match>, int>((ref, round) async {
  final service = ref.read(footballDataProvider);
  return await service.getFixtures(round: round);
});

final recentSerieAMatchesProvider = FutureProvider<List<Match>>((ref) async {
  final service = ref.read(footballDataProvider);
  return await service.getRecentResults(limit: 10);
});

/// Provider per la giornata corrente (dati reali)
final currentMatchdayProvider = FutureProvider<int>((ref) async {
  final service = ref.read(footballDataProvider);
  return await service.getCurrentMatchday();
});

/// Provider per partite della prossima giornata (dati reali)
final nextMatchdayFixturesProvider = FutureProvider<List<Match>>((ref) async {
  final service = ref.read(footballDataProvider);
  final currentMatchday = await service.getCurrentMatchday();
  return await service.getFixtures(round: currentMatchday);
});

/// Provider per le prossime partite (dati reali)
final upcomingMatchesProvider = FutureProvider<List<Match>>((ref) async {
  final service = ref.read(footballDataProvider);
  return await service.getUpcomingMatches(limit: 10);
});

/// Provider per tutte le squadre Serie A (dati reali)
final serieATeamsProvider = FutureProvider<List<Team>>((ref) async {
  final service = ref.read(footballDataProvider);
  return await service.getTeams();
});

// === COMBINED PROVIDERS ===

final serieAMatchStatusProvider =
    FutureProvider<SerieAMatchStatus>((ref) async {
  final liveMatches = await ref.watch(serieALiveMatchesProvider.future);
  final nextMatch = await ref.watch(nextSerieAMatchProvider.future);
  return SerieAMatchStatus(liveMatches: liveMatches, nextMatch: nextMatch);
});

final canMakePickProvider = Provider<bool>((ref) {
  final matchday = ref.watch(matchdayProvider);
  return matchday.when(
    data: (md) => DateTime.now().isBefore(md.deadline),
    loading: () => false,
    error: (_, __) => false,
  );
});

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

// === SUPPORT CLASSES ===

class SerieAMatchStatus {
  final List<Match> liveMatches;
  final Match? nextMatch;

  SerieAMatchStatus({required this.liveMatches, this.nextMatch});

  bool get hasLiveMatches => liveMatches.isNotEmpty;

  Duration? get timeToNextMatch {
    if (nextMatch == null) return null;
    final diff = nextMatch!.date.difference(DateTime.now());
    return diff.isNegative ? null : diff;
  }
}

class UserNotAuthenticatedException implements Exception {
  const UserNotAuthenticatedException();

  @override
  String toString() => 'Utente non autenticato';
}
