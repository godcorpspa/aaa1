import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_repo.dart';
import 'services/api_football_service.dart';
import 'models/matchday.dart';
import 'models/user_data.dart';
import 'models/pick.dart';
import 'models/league_models.dart';

// === BASE PROVIDERS ===

final repoProvider = Provider<FirestoreRepo>((ref) => FirestoreRepo());

final apiFootballProvider = Provider<ApiFootballService>((ref) {
  return ApiFootballService();
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

// === SERIE A PROVIDERS ===

final serieAStandingsProvider =
    FutureProvider<List<LeagueStanding>>((ref) async {
  final api = ref.read(apiFootballProvider);
  return await api.getStandings();
});

final serieALiveMatchesProvider = FutureProvider<List<Match>>((ref) async {
  final api = ref.read(apiFootballProvider);
  return await api.getLiveMatches();
});

final nextSerieAMatchProvider = FutureProvider<Match?>((ref) async {
  final api = ref.read(apiFootballProvider);
  return await api.getNextMatch();
});

final serieATeamNamesProvider = FutureProvider<List<String>>((ref) async {
  final api = ref.read(apiFootballProvider);
  return await api.getTeamNames();
});

final serieAFixturesProvider =
    FutureProvider.family<List<Match>, int>((ref, round) async {
  final api = ref.read(apiFootballProvider);
  return await api.getFixtures(round: round);
});

final recentSerieAMatchesProvider = FutureProvider<List<Match>>((ref) async {
  final api = ref.read(apiFootballProvider);
  final now = DateTime.now();
  final from = now.subtract(const Duration(days: 7));
  return await api.getFixtures(from: from, to: now);
});

/// Dynamically fetches fixtures for the current matchday
final nextMatchdayFixturesProvider = FutureProvider<List<Match>>((ref) async {
  final api = ref.read(apiFootballProvider);
  final matchday = await ref.watch(matchdayProvider.future);
  return await api.getFixtures(round: matchday.giornata);
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
