import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/league_models.dart';

class ApiFootballService {
  static const String _baseUrl = 'https://v3.football.api-sports.io';
  static const String _apiKey = 'YOUR_API_KEY'; // Sostituisci con la tua API key
  static const int _serieALeagueId = 135; // ID Serie A italiana

  final http.Client _client;

  ApiFootballService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'x-rapidapi-host': 'v3.football.api-sports.io',
    'x-rapidapi-key': _apiKey,
    'Content-Type': 'application/json',
  };

  /// Recupera la classifica della Serie A
  Future<List<LeagueStanding>> getStandings({int season = 2024}) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/standings?league=$_serieALeagueId&season=$season'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final standings = data['response'][0]['league']['standings'][0] as List;
        
        return standings
            .map((standing) => LeagueStanding.fromJson(standing))
            .toList();
      } else {
        throw ApiFootballException('Errore nel caricamento classifica: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiFootballException('Errore di connessione: $e');
    }
  }

  /// Recupera le partite di una giornata specifica
  Future<List<Match>> getFixtures({
    int? round,
    DateTime? from,
    DateTime? to,
    int season = 2024,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/fixtures').replace(queryParameters: {
        'league': _serieALeagueId.toString(),
        'season': season.toString(),
        if (round != null) 'round': 'Regular Season - $round',
        if (from != null) 'from': _formatDate(from),
        if (to != null) 'to': _formatDate(to),
      });

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fixtures = data['response'] as List;
        
        return fixtures.map((fixture) => Match.fromJson(fixture)).toList();
      } else {
        throw ApiFootballException('Errore nel caricamento partite: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiFootballException('Errore di connessione: $e');
    }
  }

  /// Recupera le partite live
  Future<List<Match>> getLiveMatches() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fixtures?live=all&league=$_serieALeagueId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fixtures = data['response'] as List;
        
        return fixtures.map((fixture) => Match.fromJson(fixture)).toList();
      } else {
        throw ApiFootballException('Errore nel caricamento partite live: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiFootballException('Errore di connessione: $e');
    }
  }

  /// Recupera le squadre della lega
  Future<List<Team>> getTeams({int season = 2024}) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/teams?league=$_serieALeagueId&season=$season'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final teams = data['response'] as List;
        
        return teams
            .map((teamData) => Team.fromJson(teamData['team']))
            .toList();
      } else {
        throw ApiFootballException('Errore nel caricamento squadre: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiFootballException('Errore di connessione: $e');
    }
  }

  /// Recupera la prossima partita
  Future<Match?> getNextMatch() async {
    try {
      final now = DateTime.now();
      final matches = await getFixtures(
        from: now,
        to: now.add(const Duration(days: 7)),
      );

      final upcomingMatches = matches
          .where((m) => m.status == MatchStatus.notStarted)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      return upcomingMatches.isNotEmpty ? upcomingMatches.first : null;
    } catch (e) {
      throw ApiFootballException('Errore nel caricamento prossima partita: $e');
    }
  }

  /// Recupera tutte le squadre per il dropdown
  Future<List<String>> getTeamNames({int season = 2024}) async {
    try {
      final teams = await getTeams(season: season);
      return teams.map((team) => team.name).toList()..sort();
    } catch (e) {
      throw ApiFootballException('Errore nel caricamento nomi squadre: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _client.close();
  }
}

class ApiFootballException implements Exception {
  final String message;
  
  ApiFootballException(this.message);
  
  @override
  String toString() => 'ApiFootballException: $message';
}

// Provider per dati mock Serie A (sviluppo)
class MockApiFootballService extends ApiFootballService {
  @override
  Future<List<LeagueStanding>> getStandings({int season = 2024}) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simula latenza
    
    return [
      LeagueStanding(
        position: 1,
        team: Team(id: 1, name: 'Inter', logo: ''),
        points: 97,
        played: 38,
        wins: 30,
        draws: 7,
        losses: 1,
        goalsFor: 89,
        goalsAgainst: 22,
        goalDifference: 67,
      ),
      LeagueStanding(
        position: 2,
        team: Team(id: 2, name: 'AC Milan', logo: ''),
        points: 75,
        played: 38,
        wins: 22,
        draws: 9,
        losses: 7,
        goalsFor: 76,
        goalsAgainst: 49,
        goalDifference: 27,
      ),
      LeagueStanding(
        position: 3,
        team: Team(id: 3, name: 'Juventus', logo: ''),
        points: 71,
        played: 38,
        wins: 20,
        draws: 11,
        losses: 7,
        goalsFor: 54,
        goalsAgainst: 37,
        goalDifference: 17,
      ),
      LeagueStanding(
        position: 4,
        team: Team(id: 4, name: 'Atalanta', logo: ''),
        points: 69,
        played: 38,
        wins: 21,
        draws: 6,
        losses: 11,
        goalsFor: 72,
        goalsAgainst: 42,
        goalDifference: 30,
      ),
      LeagueStanding(
        position: 5,
        team: Team(id: 5, name: 'Bologna', logo: ''),
        points: 68,
        played: 38,
        wins: 18,
        draws: 14,
        losses: 6,
        goalsFor: 54,
        goalsAgainst: 32,
        goalDifference: 22,
      ),
      LeagueStanding(
        position: 6,
        team: Team(id: 6, name: 'Roma', logo: ''),
        points: 63,
        played: 38,
        wins: 18,
        draws: 9,
        losses: 11,
        goalsFor: 65,
        goalsAgainst: 56,
        goalDifference: 9,
      ),
      LeagueStanding(
        position: 7,
        team: Team(id: 7, name: 'Lazio', logo: ''),
        points: 61,
        played: 38,
        wins: 17,
        draws: 10,
        losses: 11,
        goalsFor: 51,
        goalsAgainst: 42,
        goalDifference: 9,
      ),
      LeagueStanding(
        position: 8,
        team: Team(id: 8, name: 'Fiorentina', logo: ''),
        points: 60,
        played: 38,
        wins: 18,
        draws: 6,
        losses: 14,
        goalsFor: 72,
        goalsAgainst: 56,
        goalDifference: 16,
      ),
      LeagueStanding(
        position: 9,
        team: Team(id: 9, name: 'Torino', logo: ''),
        points: 53,
        played: 38,
        wins: 15,
        draws: 8,
        losses: 15,
        goalsFor: 36,
        goalsAgainst: 41,
        goalDifference: -5,
      ),
      LeagueStanding(
        position: 10,
        team: Team(id: 10, name: 'Napoli', logo: ''),
        points: 53,
        played: 38,
        wins: 15,
        draws: 8,
        losses: 15,
        goalsFor: 54,
        goalsAgainst: 48,
        goalDifference: 6,
      ),
      LeagueStanding(
        position: 11,
        team: Team(id: 11, name: 'Genoa', logo: ''),
        points: 49,
        played: 38,
        wins: 12,
        draws: 13,
        losses: 13,
        goalsFor: 48,
        goalsAgainst: 53,
        goalDifference: -5,
      ),
      LeagueStanding(
        position: 12,
        team: Team(id: 12, name: 'Monza', logo: ''),
        points: 45,
        played: 38,
        wins: 12,
        draws: 9,
        losses: 17,
        goalsFor: 43,
        goalsAgainst: 69,
        goalDifference: -26,
      ),
      LeagueStanding(
        position: 13,
        team: Team(id: 13, name: 'Verona', logo: ''),
        points: 38,
        played: 38,
        wins: 10,
        draws: 8,
        losses: 20,
        goalsFor: 38,
        goalsAgainst: 53,
        goalDifference: -15,
      ),
      LeagueStanding(
        position: 14,
        team: Team(id: 14, name: 'Lecce', logo: ''),
        points: 38,
        played: 38,
        wins: 8,
        draws: 14,
        losses: 16,
        goalsFor: 37,
        goalsAgainst: 58,
        goalDifference: -21,
      ),
      LeagueStanding(
        position: 15,
        team: Team(id: 15, name: 'Udinese', logo: ''),
        points: 37,
        played: 38,
        wins: 8,
        draws: 13,
        losses: 17,
        goalsFor: 36,
        goalsAgainst: 56,
        goalDifference: -20,
      ),
      LeagueStanding(
        position: 16,
        team: Team(id: 16, name: 'Cagliari', logo: ''),
        points: 36,
        played: 38,
        wins: 8,
        draws: 12,
        losses: 18,
        goalsFor: 42,
        goalsAgainst: 69,
        goalDifference: -27,
      ),
      LeagueStanding(
        position: 17,
        team: Team(id: 17, name: 'Empoli', logo: ''),
        points: 35,
        played: 38,
        wins: 8,
        draws: 11,
        losses: 19,
        goalsFor: 29,
        goalsAgainst: 49,
        goalDifference: -20,
      ),
      LeagueStanding(
        position: 18,
        team: Team(id: 18, name: 'Frosinone', logo: ''),
        points: 35,
        played: 38,
        wins: 8,
        draws: 11,
        losses: 19,
        goalsFor: 44,
        goalsAgainst: 68,
        goalDifference: -24,
      ),
      LeagueStanding(
        position: 19,
        team: Team(id: 19, name: 'Sassuolo', logo: ''),
        points: 30,
        played: 38,
        wins: 7,
        draws: 9,
        losses: 22,
        goalsFor: 46,
        goalsAgainst: 77,
        goalDifference: -31,
      ),
      LeagueStanding(
        position: 20,
        team: Team(id: 20, name: 'Salernitana', logo: ''),
        points: 17,
        played: 38,
        wins: 2,
        draws: 11,
        losses: 25,
        goalsFor: 26,
        goalsAgainst: 73,
        goalDifference: -47,
      ),
    ];
  }

  @override
  Future<List<Match>> getLiveMatches() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simula partite live solo se è un orario plausibile (es. weekend pomeriggio)
    final now = DateTime.now();
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final isAfternoon = now.hour >= 15 && now.hour <= 22;
    
    if (isWeekend && isAfternoon) {
      return [
        Match(
          id: 1,
          homeTeam: Team(id: 1, name: 'Inter', logo: ''),
          awayTeam: Team(id: 2, name: 'AC Milan', logo: ''),
          date: now.subtract(const Duration(minutes: 65)),
          status: MatchStatus.live,
          homeScore: 2,
          awayScore: 1,
          minute: 65,
          venue: 'San Siro',
        ),
        Match(
          id: 2,
          homeTeam: Team(id: 3, name: 'Juventus', logo: ''),
          awayTeam: Team(id: 6, name: 'Roma', logo: ''),
          date: now.subtract(const Duration(minutes: 30)),
          status: MatchStatus.live,
          homeScore: 1,
          awayScore: 0,
          minute: 30,
          venue: 'Allianz Stadium',
        ),
      ];
    }
    
    return []; // Nessuna partita live
  }

  @override
  Future<Match?> getNextMatch() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Prossima partita nel weekend
    final now = DateTime.now();
    DateTime nextSaturday = now.add(Duration(days: (DateTime.saturday - now.weekday) % 7));
    if (nextSaturday.isBefore(now) || nextSaturday.day == now.day) {
      nextSaturday = nextSaturday.add(const Duration(days: 7));
    }
    final matchTime = DateTime(nextSaturday.year, nextSaturday.month, nextSaturday.day, 20, 45);
    
    return Match(
      id: 3,
      homeTeam: Team(id: 4, name: 'Atalanta', logo: ''),
      awayTeam: Team(id: 7, name: 'Lazio', logo: ''),
      date: matchTime,
      status: MatchStatus.notStarted,
      venue: 'Gewiss Stadium',
    );
  }

  @override
  Future<List<String>> getTeamNames({int season = 2024}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return [
      'Atalanta',
      'Bologna',
      'Cagliari',
      'Empoli',
      'Fiorentina',
      'Frosinone',
      'Genoa',
      'Inter',
      'Juventus',
      'Lazio',
      'Lecce',
      'AC Milan',
      'Monza',
      'Napoli',
      'Roma',
      'Salernitana',
      'Sassuolo',
      'Torino',
      'Udinese',
      'Verona',
    ];
  }

  @override
  Future<List<Match>> getFixtures({
    int? round,
    DateTime? from,
    DateTime? to,
    int season = 2024,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final now = DateTime.now();
    
    // Se è richiesta una giornata specifica, restituisci le partite di quella giornata
    if (round != null) {
      return _getMatchdayFixtures(round);
    }
    
    // Altrimenti risultati recenti (ultimi 3 giorni)
    return [
      Match(
        id: 101,
        homeTeam: Team(id: 1, name: 'Inter', logo: ''),
        awayTeam: Team(id: 10, name: 'Napoli', logo: ''),
        date: now.subtract(const Duration(days: 2)),
        status: MatchStatus.finished,
        homeScore: 3,
        awayScore: 0,
        venue: 'San Siro',
      ),
      Match(
        id: 102,
        homeTeam: Team(id: 3, name: 'Juventus', logo: ''),
        awayTeam: Team(id: 4, name: 'Atalanta', logo: ''),
        date: now.subtract(const Duration(days: 2)),
        status: MatchStatus.finished,
        homeScore: 1,
        awayScore: 2,
        venue: 'Allianz Stadium',
      ),
      Match(
        id: 103,
        homeTeam: Team(id: 2, name: 'AC Milan', logo: ''),
        awayTeam: Team(id: 8, name: 'Fiorentina', logo: ''),
        date: now.subtract(const Duration(days: 1)),
        status: MatchStatus.finished,
        homeScore: 2,
        awayScore: 1,
        venue: 'San Siro',
      ),
      Match(
        id: 104,
        homeTeam: Team(id: 6, name: 'Roma', logo: ''),
        awayTeam: Team(id: 7, name: 'Lazio', logo: ''),
        date: now.subtract(const Duration(days: 1)),
        status: MatchStatus.finished,
        homeScore: 1,
        awayScore: 1,
        venue: 'Stadio Olimpico',
      ),
      Match(
        id: 105,
        homeTeam: Team(id: 5, name: 'Bologna', logo: ''),
        awayTeam: Team(id: 15, name: 'Udinese', logo: ''),
        date: now.subtract(const Duration(days: 3)),
        status: MatchStatus.finished,
        homeScore: 3,
        awayScore: 1,
        venue: 'Stadio Renato Dall\'Ara',
      ),
    ];
  }

  /// Restituisce tutte le partite di una giornata specifica
  List<Match> _getMatchdayFixtures(int round) {
    final now = DateTime.now();
    DateTime nextSaturday = now.add(Duration(days: (DateTime.saturday - now.weekday) % 7));
    if (nextSaturday.isBefore(now) || nextSaturday.day == now.day) {
      nextSaturday = nextSaturday.add(const Duration(days: 7));
    }

    // Tutte le partite della giornata
    return [
      Match(
        id: 201,
        homeTeam: Team(id: 4, name: 'Atalanta', logo: ''),
        awayTeam: Team(id: 7, name: 'Lazio', logo: ''),
        date: DateTime(nextSaturday.year, nextSaturday.month, nextSaturday.day, 15, 0),
        status: MatchStatus.notStarted,
        venue: 'Gewiss Stadium',
      ),
      Match(
        id: 202,
        homeTeam: Team(id: 1, name: 'Inter', logo: ''),
        awayTeam: Team(id: 2, name: 'AC Milan', logo: ''),
        date: DateTime(nextSaturday.year, nextSaturday.month, nextSaturday.day, 18, 0),
        status: MatchStatus.notStarted,
        venue: 'San Siro',
      ),
      Match(
        id: 203,
        homeTeam: Team(id: 3, name: 'Juventus', logo: ''),
        awayTeam: Team(id: 6, name: 'Roma', logo: ''),
        date: DateTime(nextSaturday.year, nextSaturday.month, nextSaturday.day, 20, 45),
        status: MatchStatus.notStarted,
        venue: 'Allianz Stadium',
      ),
      Match(
        id: 204,
        homeTeam: Team(id: 5, name: 'Bologna', logo: ''),
        awayTeam: Team(id: 8, name: 'Fiorentina', logo: ''),
        date: DateTime(nextSaturday.year, nextSaturday.month, nextSaturday.day + 1, 15, 0),
        status: MatchStatus.notStarted,
        venue: 'Stadio Renato Dall\'Ara',
      ),
      Match(
        id: 205,
        homeTeam: Team(id: 10, name: 'Napoli', logo: ''),
        awayTeam: Team(id: 9, name: 'Torino', logo: ''),
        date: DateTime(nextSaturday.year, nextSaturday.month, nextSaturday.day + 1, 18, 0),
        status: MatchStatus.notStarted,
        venue: 'Stadio Diego Armando Maradona',
      ),
    ];
  }
}