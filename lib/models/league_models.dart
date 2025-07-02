// Modelli per dati campionato irlandese

class LeagueStanding {
  final int position;
  final Team team;
  final int points;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;

  LeagueStanding({
    required this.position,
    required this.team,
    required this.points,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
  });

  factory LeagueStanding.fromJson(Map<String, dynamic> json) {
    final stats = json['all'] ?? {};
    return LeagueStanding(
      position: json['rank'] ?? 0,
      team: Team.fromJson(json['team'] ?? {}),
      points: json['points'] ?? 0,
      played: stats['played'] ?? 0,
      wins: stats['win'] ?? 0,
      draws: stats['draw'] ?? 0,
      losses: stats['lose'] ?? 0,
      goalsFor: stats['goals']?['for'] ?? 0,
      goalsAgainst: stats['goals']?['against'] ?? 0,
      goalDifference: json['goalsDiff'] ?? 0,
    );
  }
}

class Team {
  final int id;
  final String name;
  final String logo;

  Team({
    required this.id,
    required this.name,
    required this.logo,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      logo: json['logo'] ?? '',
    );
  }
}

enum MatchStatus {
  notStarted,
  live,
  finished,
  postponed,
  cancelled,
}

class Match {
  final int id;
  final Team homeTeam;
  final Team awayTeam;
  final DateTime date;
  final MatchStatus status;
  final int? homeScore;
  final int? awayScore;
  final int? minute;
  final String venue;

  Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.date,
    required this.status,
    this.homeScore,
    this.awayScore,
    this.minute,
    required this.venue,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    final fixture = json['fixture'] ?? {};
    final teams = json['teams'] ?? {};
    final goals = json['goals'] ?? {};
    
    return Match(
      id: fixture['id'] ?? 0,
      homeTeam: Team.fromJson(teams['home'] ?? {}),
      awayTeam: Team.fromJson(teams['away'] ?? {}),
      date: DateTime.parse(fixture['date'] ?? DateTime.now().toIso8601String()),
      status: _parseStatus(fixture['status']?['short'] ?? ''),
      homeScore: goals['home'],
      awayScore: goals['away'],
      minute: fixture['status']?['elapsed'],
      venue: fixture['venue']?['name'] ?? '',
    );
  }

  static MatchStatus _parseStatus(String status) {
    switch (status) {
      case 'NS':
      case 'TBD':
        return MatchStatus.notStarted;
      case '1H':
      case 'HT':
      case '2H':
      case 'ET':
      case 'P':
        return MatchStatus.live;
      case 'FT':
      case 'AET':
      case 'PEN':
        return MatchStatus.finished;
      case 'PST':
        return MatchStatus.postponed;
      case 'CANC':
        return MatchStatus.cancelled;
      default:
        return MatchStatus.notStarted;
    }
  }

  bool get isLive => status == MatchStatus.live;
  bool get isFinished => status == MatchStatus.finished;
  bool get hasStarted => status != MatchStatus.notStarted;

  String get displayScore {
    if (homeScore != null && awayScore != null) {
      return '$homeScore - $awayScore';
    }
    return '-';
  }

  String get statusText {
    switch (status) {
      case MatchStatus.notStarted:
        return 'VS';
      case MatchStatus.live:
        return minute != null ? '$minute\'' : 'LIVE';
      case MatchStatus.finished:
        return 'FT';
      case MatchStatus.postponed:
        return 'RINV';
      case MatchStatus.cancelled:
        return 'CANC';
    }
  }
}

class Gameweek {
  final int round;
  final List<Match> matches;
  final DateTime startDate;
  final DateTime endDate;

  Gameweek({
    required this.round,
    required this.matches,
    required this.startDate,
    required this.endDate,
  });

  List<Match> get liveMatches => matches.where((m) => m.isLive).toList();
  bool get hasLiveMatches => liveMatches.isNotEmpty;

  Match? get nextMatch {
    final upcoming = matches
        .where((m) => m.status == MatchStatus.notStarted)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    
    return upcoming.isNotEmpty ? upcoming.first : null;
  }
}

class UserLeague {
  final String id;
  final String name;
  final String description;
  final bool isPrivate;
  final String creatorName;
  final DateTime createdAt;
  final int maxParticipants;
  final int currentParticipants;
  final String? inviteCode;
  final List<String> participants;

  UserLeague({
    required this.id,
    required this.name,
    required this.description,
    required this.isPrivate,
    required this.creatorName,
    required this.createdAt,
    this.maxParticipants = 100,
    this.currentParticipants = 0,
    this.inviteCode,
    this.participants = const [],
  });

  bool get isFull => currentParticipants >= maxParticipants;
  bool get isPublic => !isPrivate;
  
  bool isParticipant(String userId) => participants.contains(userId);
}