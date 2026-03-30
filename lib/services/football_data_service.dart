import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/league_models.dart';

/// Service per Football-Data.org API (Serie A)
/// Documentazione: https://www.football-data.org/documentation/api
class FootballDataService {
  static const String _baseUrl = 'https://api.football-data.org/v4';
  static const String _apiKey = 'fe115031ba4c451f8eaa62f96a30a261';
  static const String _serieACode = 'SA'; // Serie A competition code

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
    // Controlla cache
    if (_standingsCache != null && 
        _standingsCacheTime != null &&
        DateTime.now().difference(_standingsCacheTime!) < _cacheDuration) {
      return _parseStandings(_standingsCache!);
    }

    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/competitions/$_serieACode/standings'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Aggiorna cache
        _standingsCache = data;
        _standingsCacheTime = DateTime.now();
        
        return _parseStandings(data);
      } else if (response.statusCode == 429) {
        throw FootballDataException('Limite API raggiunto. Riprova tra un minuto.');
      } else {
        throw FootballDataException('Errore nel caricamento classifica: ${response.statusCode}');
      }
    } catch (e) {
      if (e is FootballDataException) rethrow;
      throw FootballDataException('Errore di connessione: $e');
    }
  }

  List<LeagueStanding> _parseStandings(Map<String, dynamic> data) {
    final standings = data['standings'] as List?;
    if (standings == null || standings.isEmpty) {
      throw FootballDataException('Dati classifica non disponibili');
    }

    // Prendi la classifica "TOTAL" (non HOME o AWAY)
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
          logo: team['crest'] ?? '', // Football-Data usa 'crest' per il logo
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
    String? status, // SCHEDULED, LIVE, IN_PLAY, PAUSED, FINISHED, POSTPONED, CANCELLED
    int? matchday,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (status != null) queryParams['status'] = status;
      if (matchday != null) queryParams['matchday'] = matchday.toString();
      if (dateFrom != null) queryParams['dateFrom'] = _formatDate(dateFrom);
      if (dateTo != null) queryParams['dateTo'] = _formatDate(dateTo);

      final uri = Uri.parse('$_baseUrl/competitions/$_serieACode/matches')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await _client.get(uri, headers: _headers);

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
    // Football-Data non fornisce sempre il minuto esatto
    // Possiamo stimarlo se la partita è in corso
    if (match['status'] == 'IN_PLAY' || match['status'] == 'PAUSED') {
      final startTime = DateTime.tryParse(match['utcDate'] ?? '');
      if (startTime != null) {
        final elapsed = DateTime.now().difference(startTime).inMinutes;
        // Aggiungi pausa per l'intervallo se > 45 minuti
        if (elapsed > 45 && elapsed < 60) {
          return 45; // Intervallo
        }
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
    return getMatches(
      matchday: round,
      dateFrom: from,
      dateTo: to,
    );
  }

  /// Recupera la prossima partita
  Future<Match?> getNextMatch() async {
    try {
      final matches = await getMatches(status: 'SCHEDULED');
      
      if (matches.isEmpty) return null;
      
      // Ordina per data e prendi la prima
      matches.sort((a, b) => a.date.compareTo(b.date));
      return matches.first;
    } catch (e) {
      throw FootballDataException('Errore nel caricamento prossima partita: $e');
    }
  }

  /// Recupera tutte le squadre della Serie A
  Future<List<Team>> getTeams() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/competitions/$_serieACode/teams'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final teams = data['teams'] as List;
        
        return teams.map((team) => Team(
          id: team['id'] ?? 0,
          name: team['name'] ?? '',
          logo: team['crest'] ?? '',
        )).toList();
      } else if (response.statusCode == 429) {
        throw FootballDataException('Limite API raggiunto. Riprova tra un minuto.');
      } else {
        throw FootballDataException('Errore nel caricamento squadre: ${response.statusCode}');
      }
    } catch (e) {
      if (e is FootballDataException) rethrow;
      throw FootballDataException('Errore di connessione: $e');
    }
  }

  /// Recupera i nomi delle squadre (per dropdown)
  Future<List<String>> getTeamNames() async {
    try {
      final teams = await getTeams();
      return teams.map((team) => team.name).toList()..sort();
    } catch (e) {
      throw FootballDataException('Errore nel caricamento nomi squadre: $e');
    }
  }

  /// Recupera la giornata corrente
  Future<int> getCurrentMatchday() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/competitions/$_serieACode'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final currentSeason = data['currentSeason'];
        return currentSeason?['currentMatchday'] ?? 1;
      } else {
        throw FootballDataException('Errore nel caricamento giornata corrente');
      }
    } catch (e) {
      if (e is FootballDataException) rethrow;
      throw FootballDataException('Errore di connessione: $e');
    }
  }

  /// Recupera informazioni sulla competizione
  Future<Map<String, dynamic>> getCompetitionInfo() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/competitions/$_serieACode'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw FootballDataException('Errore nel caricamento info competizione');
      }
    } catch (e) {
      if (e is FootballDataException) rethrow;
      throw FootballDataException('Errore di connessione: $e');
    }
  }

  /// Recupera i risultati recenti (ultime partite finite)
  Future<List<Match>> getRecentResults({int limit = 10}) async {
    try {
      final matches = await getMatches(status: 'FINISHED');
      
      // Ordina per data decrescente e prendi le ultime
      matches.sort((a, b) => b.date.compareTo(a.date));
      return matches.take(limit).toList();
    } catch (e) {
      throw FootballDataException('Errore nel caricamento risultati recenti: $e');
    }
  }

  /// Recupera le prossime partite
  Future<List<Match>> getUpcomingMatches({int limit = 10}) async {
    try {
      final matches = await getMatches(status: 'SCHEDULED');
      
      // Ordina per data crescente e prendi le prossime
      matches.sort((a, b) => a.date.compareTo(b.date));
      return matches.take(limit).toList();
    } catch (e) {
      throw FootballDataException('Errore nel caricamento prossime partite: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Invalida la cache
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