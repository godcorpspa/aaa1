import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/league_models.dart';

class ApiFootballService {
  static const String _baseUrl = 'https://v3.football.api-sports.io';
  static const int _serieALeagueId = 135;

  final http.Client _client;
  final String _apiKey;

  ApiFootballService({
    http.Client? client,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ??
            const String.fromEnvironment('API_FOOTBALL_KEY',
                defaultValue: '');

  Map<String, String> get _headers => {
        'x-rapidapi-host': 'v3.football.api-sports.io',
        'x-rapidapi-key': _apiKey,
      };

  int get _currentSeason {
    final now = DateTime.now();
    // Serie A season spans Aug-May. If before August, use previous year.
    return now.month >= 8 ? now.year : now.year - 1;
  }

  Future<List<LeagueStanding>> getStandings({int? season}) async {
    final s = season ?? _currentSeason;
    final data = await _get('/standings', {
      'league': '$_serieALeagueId',
      'season': '$s',
    });
    final standings =
        data['response'][0]['league']['standings'][0] as List;
    return standings.map((s) => LeagueStanding.fromJson(s)).toList();
  }

  Future<List<Match>> getFixtures({
    int? round,
    DateTime? from,
    DateTime? to,
    int? season,
  }) async {
    final s = season ?? _currentSeason;
    final params = <String, String>{
      'league': '$_serieALeagueId',
      'season': '$s',
    };
    if (round != null) params['round'] = 'Regular Season - $round';
    if (from != null) params['from'] = _formatDate(from);
    if (to != null) params['to'] = _formatDate(to);

    final data = await _get('/fixtures', params);
    final fixtures = data['response'] as List;
    return fixtures.map((f) => Match.fromJson(f)).toList();
  }

  Future<List<Match>> getLiveMatches() async {
    final data = await _get('/fixtures', {
      'live': 'all',
      'league': '$_serieALeagueId',
    });
    final fixtures = data['response'] as List;
    return fixtures.map((f) => Match.fromJson(f)).toList();
  }

  Future<List<Team>> getTeams({int? season}) async {
    final s = season ?? _currentSeason;
    final data = await _get('/teams', {
      'league': '$_serieALeagueId',
      'season': '$s',
    });
    final teams = data['response'] as List;
    return teams.map((t) => Team.fromJson(t['team'])).toList();
  }

  Future<Match?> getNextMatch() async {
    final now = DateTime.now();
    final matches = await getFixtures(
      from: now,
      to: now.add(const Duration(days: 14)),
    );
    final upcoming = matches
        .where((m) => m.status == MatchStatus.notStarted)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  Future<List<String>> getTeamNames({int? season}) async {
    final teams = await getTeams(season: season);
    return teams.map((t) => t.name).toList()..sort();
  }

  /// Fetches the current round number
  Future<int?> getCurrentRound({int? season}) async {
    final s = season ?? _currentSeason;
    final data = await _get('/fixtures/rounds', {
      'league': '$_serieALeagueId',
      'season': '$s',
      'current': 'true',
    });
    final rounds = data['response'] as List;
    if (rounds.isEmpty) return null;
    // Format: "Regular Season - 15"
    final roundStr = rounds.first as String;
    final match = RegExp(r'(\d+)$').firstMatch(roundStr);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  Future<Map<String, dynamic>> _get(
      String endpoint, Map<String, String> params) async {
    if (_apiKey.isEmpty) {
      throw ApiFootballException(
          'API key non configurata. Imposta API_FOOTBALL_KEY.');
    }

    final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: params);

    try {
      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 429) {
        throw ApiFootballException('Limite richieste API raggiunto. Riprova tra poco.');
      } else {
        throw ApiFootballException(
            'Errore API: ${response.statusCode}');
      }
    } on ApiFootballException {
      rethrow;
    } catch (e) {
      throw ApiFootballException('Errore di connessione: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void dispose() => _client.close();
}

class ApiFootballException implements Exception {
  final String message;
  ApiFootballException(this.message);

  @override
  String toString() => message;
}
