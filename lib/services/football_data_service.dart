import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/league_models.dart';

/// Service per Football-Data.org API (Serie A)
/// Documentazione: https://www.football-data.org/documentation/api
class FootballDataService {
  static const String _baseUrl = 'https://api.football-data.org/v4';
  static const String _apiKey = String.fromEnvironment(
    'FOOTBALL_DATA_KEY',
    defaultValue: 'fe115031ba4c451f8eaa62f96a30a261',
  );
  static const String _serieACode = 'SA';

  final http.Client _client;

  // Cache per ridurre le chiamate API (limite: 10/minuto piano gratuito)
  Map<String, dynamic>? _standingsCache;
  DateTime? _standingsCacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  FootballDataService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'X-Auth-Token': _apiKey,
    'Content-Type': 'application/json',
  };

  /// Recupera la classifica della Serie A
  Future<List<LeagueStanding>> getStandings() async {
    if (_standingsCache != null &&
        _standingsCacheTime != null &&
        DateTime.now().difference(_standingsCacheTime!) < _cacheDuration) {
      return _parseStandings(_standingsCache!);
    }

    final response = await _get('/competitions/$_serieACode/standings');
    _standingsCache = response;
    _standingsCacheTime = DateTime.now();
    return _parseStandings(response);
  }

  List<LeagueStanding> _parseStandings(Map<String, dynamic> data) {
    final standings = data['standings'] as List?;
    if (standings == null || standings.isEmpty) {
      throw FootballDataException('Dati classifica non disponibili');
    }

    final totalStandings = standings.firstWhere(
      (s) => s['type'] == 'TOTAL',
      orElse: () => standings.first,
    );

    final table = totalStandings['table'] as List;

    return table.map((entry) {
      final team = entry['team'];
      return LeagueStanding(
        position: entry['position'] ?? 0,
        team: Team(
          id: team['id'] ?? 0,
          name: team['name'] ?? '',
          logo: team['crest'] ?? '',
        ),
        points: entry['points'] ?? 0,
        played: entry['playedGames'] ?? 0,
        wins: entry['won'] ?? 0,
        draws: entry['draw'] ?? 0,
        losses: entry['lost'] ?? 0,
        goalsFor: entry['goalsFor'] ?? 0,
        goalsAgainst: entry['goalsAgainst'] ?? 0,
        goalDifference: entry['goalDifference'] ?? 0,
      );
    }).toList();
  }

  /// Recupera le partite (con filtri opzionali)
  Future<List<Match>> getMatches({
    String? status,
    int? matchday,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final queryParams = <String, String>{};

    if (status != null) queryParams['status'] = status;
    if (matchday != null) queryParams['matchday'] = matchday.toString();
    if (dateFrom != null) queryParams['dateFrom'] = _formatDate(dateFrom);
    if (dateTo != null) queryParams['dateTo'] = _formatDate(dateTo);

    final uri = Uri.parse('$_baseUrl/competitions/$_serieACode/matches')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await _client.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matches = data['matches'] as List;
        return matches.map((match) => _parseMatch(match)).toList();
      } else if (response.statusCode == 429) {
        throw FootballDataException('Limite API raggiunto. Riprova tra un minuto.');
      } else {
        throw FootballDataException('Errore nel caricamento partite: ${response.statusCode}');
      }
    } catch (e) {
      if (e is FootballDataException) rethrow;
      throw FootballDataException('Errore di connessione: $e');
    }
  }

  Match _parseMatch(Map<String, dynamic> match) {
    final homeTeam = match['homeTeam'];
    final awayTeam = match['awayTeam'];
    final score = match['score'];
    final fullTime = score?['fullTime'];

    return Match(
      id: match['id'] ?? 0,
      homeTeam: Team(
        id: homeTeam?['id'] ?? 0,
        name: homeTeam?['name'] ?? '',
        logo: homeTeam?['crest'] ?? '',
      ),
      awayTeam: Team(
        id: awayTeam?['id'] ?? 0,
        name: awayTeam?['name'] ?? '',
        logo: awayTeam?['crest'] ?? '',
      ),
      date: DateTime.parse(match['utcDate'] ?? DateTime.now().toIso8601String()),
      status: _parseMatchStatus(match['status']),
      homeScore: fullTime?['home'],
      awayScore: fullTime?['away'],
      minute: _parseMinute(match),
      venue: match['venue'] ?? '',
      matchday: match['matchday'] is int ? match['matchday'] as int : null,
    );
  }

  MatchStatus _parseMatchStatus(String? status) {
    switch (status) {
      case 'SCHEDULED':
      case 'TIMED':
        return MatchStatus.notStarted;
      case 'IN_PLAY':
      case 'PAUSED':
      case 'LIVE':
        return MatchStatus.live;
      case 'FINISHED':
        return MatchStatus.finished;
      case 'POSTPONED':
        return MatchStatus.postponed;
      case 'CANCELLED':
      case 'SUSPENDED':
        return MatchStatus.cancelled;
      default:
        return MatchStatus.notStarted;
    }
  }

  int? _parseMinute(Map<String, dynamic> match) {
    if (match['status'] == 'IN_PLAY' || match['status'] == 'PAUSED') {
      final startTime = DateTime.tryParse(match['utcDate'] ?? '');
      if (startTime != null) {
        final elapsed = DateTime.now().difference(startTime).inMinutes;
        if (elapsed > 45 && elapsed < 60) return 45;
        return elapsed > 90 ? 90 : elapsed;
      }
    }
    return null;
  }

  /// Recupera le partite live
  Future<List<Match>> getLiveMatches() async {
    return getMatches(status: 'LIVE');
  }

  /// Recupera le partite di una giornata specifica
  Future<List<Match>> getFixtures({int? round, DateTime? from, DateTime? to}) async {
    return getMatches(matchday: round, dateFrom: from, dateTo: to);
  }

  /// Recupera la prossima partita
  Future<Match?> getNextMatch() async {
    final matches = await getMatches(status: 'SCHEDULED');
    if (matches.isEmpty) return null;
    matches.sort((a, b) => a.date.compareTo(b.date));
    return matches.first;
  }

  /// Recupera tutte le squadre della Serie A
  Future<List<Team>> getTeams() async {
    final data = await _get('/competitions/$_serieACode/teams');
    final teams = data['teams'] as List;

    return teams.map((team) => Team(
      id: team['id'] ?? 0,
      name: team['name'] ?? '',
      logo: team['crest'] ?? '',
    )).toList();
  }

  /// Recupera i nomi delle squadre (per dropdown)
  Future<List<String>> getTeamNames() async {
    final teams = await getTeams();
    return teams.map((team) => team.name).toList()..sort();
  }

  /// Recupera la giornata corrente
  Future<int> getCurrentMatchday() async {
    final data = await _get('/competitions/$_serieACode');
    final currentSeason = data['currentSeason'];
    return currentSeason?['currentMatchday'] ?? 1;
  }

  /// Returns the next playable matchday (the lowest matchday number with at
  /// least one SCHEDULED match) along with its matches sorted by kickoff.
  ///
  /// This is what the game should target: if the currently-playing matchday
  /// has already started, picks for it are locked and the user should be
  /// able to pick for the next one instead.
  Future<NextPlayableMatchday> getNextPlayableMatchday() async {
    final scheduled = await getMatches(status: 'SCHEDULED');
    if (scheduled.isEmpty) {
      // Fallback: nothing scheduled → use API "currentMatchday"
      final current = await getCurrentMatchday();
      return NextPlayableMatchday(
        matchday: current < 1 ? 1 : current,
        matches: const <Match>[],
      );
    }

    // Bucket by matchday and pick the smallest matchday number.
    final byMatchday = <int, List<Match>>{};
    for (final m in scheduled) {
      final md = _matchdayNumberForMatch(m);
      if (md == null) continue;
      byMatchday.putIfAbsent(md, () => <Match>[]).add(m);
    }

    if (byMatchday.isEmpty) {
      // Fallback: sort by date, infer smallest matchday by earliest kickoff.
      scheduled.sort((a, b) => a.date.compareTo(b.date));
      return NextPlayableMatchday(
        matchday: await getCurrentMatchday(),
        matches: scheduled,
      );
    }

    final smallestMd = byMatchday.keys.reduce((a, b) => a < b ? a : b);
    final list = byMatchday[smallestMd]!
      ..sort((a, b) => a.date.compareTo(b.date));

    return NextPlayableMatchday(
      matchday: smallestMd < 1 ? 1 : smallestMd,
      matches: list,
    );
  }

  int? _matchdayNumberForMatch(Match match) => match.matchday;

  /// Recupera i risultati recenti (ultime partite finite)
  Future<List<Match>> getRecentResults({int limit = 10}) async {
    final matches = await getMatches(status: 'FINISHED');
    matches.sort((a, b) => b.date.compareTo(a.date));
    return matches.take(limit).toList();
  }

  /// Recupera le prossime partite
  Future<List<Match>> getUpcomingMatches({int limit = 10}) async {
    final matches = await getMatches(status: 'SCHEDULED');
    matches.sort((a, b) => a.date.compareTo(b.date));
    return matches.take(limit).toList();
  }

  /// Centralized GET request with error handling and timeout
  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 429) {
        throw FootballDataException('Limite API raggiunto. Riprova tra un minuto.');
      } else {
        throw FootballDataException('Errore API: ${response.statusCode}');
      }
    } catch (e) {
      if (e is FootballDataException) rethrow;
      throw FootballDataException('Errore di connessione: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void invalidateCache() {
    _standingsCache = null;
    _standingsCacheTime = null;
  }

  void dispose() {
    _client.close();
  }
}

/// Eccezione personalizzata per errori Football-Data API
class FootballDataException implements Exception {
  final String message;

  FootballDataException(this.message);

  @override
  String toString() => 'FootballDataException: $message';
}

/// Result of [FootballDataService.getNextPlayableMatchday].
class NextPlayableMatchday {
  final int matchday;
  final List<Match> matches;

  const NextPlayableMatchday({
    required this.matchday,
    required this.matches,
  });

  /// First match of this matchday (kickoff time). `null` if no matches.
  Match? get firstMatch => matches.isNotEmpty ? matches.first : null;

  /// Last match of this matchday. `null` if no matches.
  Match? get lastMatch => matches.isNotEmpty ? matches.last : null;
}
