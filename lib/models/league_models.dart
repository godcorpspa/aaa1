import 'package:cloud_firestore/cloud_firestore.dart';

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

// Enums per lo stato della lega
enum LeagueStatus {
  waiting,    // In attesa di partecipanti
  active,     // Lega attiva in corso
  paused,     // Lega in pausa
  completed,  // Lega terminata
  cancelled,  // Lega cancellata
}

// Enums per i tipi di giornata speciale
enum SpecialMatchdayType {
  normal,           // Giornata normale
  homeOnly,         // Solo squadre in casa
  awayOnly,         // Solo squadre in trasferta
  topTableOnly,     // Solo prime 10 in classifica
  bottomTableOnly,  // Solo ultime 10 in classifica
  highOddsOnly,     // Solo squadre con quote > 2.0
  doubleDownRound,  // Giornata double down obbligatoria
  finalRound,       // Giornata finale
}

// Modello completo per una lega Last Man Standing
class LastManStandingLeague {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;
  final bool isPrivate;
  final bool requirePassword;
  final String? password;
  final int maxParticipants;
  final int currentParticipants;
  final List<String> participants;
  final List<String> admins;
  final LeagueStatus status;
  final LeagueSettings settings;
  final String? inviteCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final LeagueStats stats;
  final Map<String, dynamic>? customRules;

  LastManStandingLeague({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    this.isPrivate = false,
    this.requirePassword = false,
    this.password,
    this.maxParticipants = 50,
    this.currentParticipants = 0,
    this.participants = const [],
    this.admins = const [],
    this.status = LeagueStatus.waiting,
    this.settings = const LeagueSettings(),
    this.inviteCode,
    this.startDate,
    this.endDate,
    this.stats = const LeagueStats(),
    this.customRules,
  });

  factory LastManStandingLeague.fromJson(Map<String, dynamic> json) {
    return LastManStandingLeague(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      creatorId: json['creatorId'] ?? '',
      creatorName: json['creatorName'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPrivate: json['isPrivate'] ?? false,
      requirePassword: json['requirePassword'] ?? false,
      password: json['password'],
      maxParticipants: json['maxParticipants'] ?? 50,
      currentParticipants: json['currentParticipants'] ?? 0,
      participants: List<String>.from(json['participants'] ?? []),
      admins: List<String>.from(json['admins'] ?? []),
      status: LeagueStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LeagueStatus.waiting,
      ),
      settings: LeagueSettings.fromJson(json['settings'] ?? {}),
      inviteCode: json['inviteCode'],
      startDate: (json['startDate'] as Timestamp?)?.toDate(),
      endDate: (json['endDate'] as Timestamp?)?.toDate(),
      stats: LeagueStats.fromJson(json['stats'] ?? {}),
      customRules: json['customRules'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPrivate': isPrivate,
      'requirePassword': requirePassword,
      'password': password,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'participants': participants,
      'admins': admins,
      'status': status.name,
      'settings': settings.toJson(),
      'inviteCode': inviteCode,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'stats': stats.toJson(),
      'customRules': customRules,
    };
  }

  // Getters di utilità
  bool get isFull => currentParticipants >= maxParticipants;
  bool get isActive => status == LeagueStatus.active;
  bool get canJoin => !isFull && status == LeagueStatus.waiting;
 bool isCreator(String userId) => creatorId == userId;
  bool isAdmin(String userId) => admins.contains(userId) || creatorId == userId;
  bool get hasStarted => startDate != null && DateTime.now().isAfter(startDate!);

  LastManStandingLeague copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    String? creatorName,
    DateTime? createdAt,
    bool? isPrivate,
    bool? requirePassword,
    String? password,
    int? maxParticipants,
    int? currentParticipants,
    List<String>? participants,
    List<String>? admins,
    LeagueStatus? status,
    LeagueSettings? settings,
    String? inviteCode,
    DateTime? startDate,
    DateTime? endDate,
    LeagueStats? stats,
    Map<String, dynamic>? customRules,
  }) {
    return LastManStandingLeague(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      isPrivate: isPrivate ?? this.isPrivate,
      requirePassword: requirePassword ?? this.requirePassword,
      password: password ?? this.password,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      participants: participants ?? this.participants,
      admins: admins ?? this.admins,
      status: status ?? this.status,
      settings: settings ?? this.settings,
      inviteCode: inviteCode ?? this.inviteCode,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      stats: stats ?? this.stats,
      customRules: customRules ?? this.customRules,
    );
  }
}

// Impostazioni della lega
class LeagueSettings {
  final bool allowJolly;
  final int maxJollyPerPlayer;
  final int jollyPrice;
  final bool allowDoubleDown;
  final bool allowGoldenTicket;
  final bool enableThemedRounds;
  final List<SpecialMatchdayType> specialMatchdays;
  final bool autoElimination;
  final bool allowLateJoin;
  final int maxLateJoinRound;

  const LeagueSettings({
    this.allowJolly = true,
    this.maxJollyPerPlayer = 3,
    this.jollyPrice = 50,
    this.allowDoubleDown = true,
    this.allowGoldenTicket = true,
    this.enableThemedRounds = true,
    this.specialMatchdays = const [],
    this.autoElimination = true,
    this.allowLateJoin = false,
    this.maxLateJoinRound = 3,
  });

  factory LeagueSettings.fromJson(Map<String, dynamic> json) {
    return LeagueSettings(
      allowJolly: json['allowJolly'] ?? true,
      maxJollyPerPlayer: json['maxJollyPerPlayer'] ?? 3,
      jollyPrice: json['jollyPrice'] ?? 50,
      allowDoubleDown: json['allowDoubleDown'] ?? true,
      allowGoldenTicket: json['allowGoldenTicket'] ?? true,
      enableThemedRounds: json['enableThemedRounds'] ?? true,
      specialMatchdays: (json['specialMatchdays'] as List?)
          ?.map((e) => SpecialMatchdayType.values.firstWhere(
                (type) => type.name == e,
                orElse: () => SpecialMatchdayType.normal,
              ))
          .toList() ?? [],
      autoElimination: json['autoElimination'] ?? true,
      allowLateJoin: json['allowLateJoin'] ?? false,
      maxLateJoinRound: json['maxLateJoinRound'] ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowJolly': allowJolly,
      'maxJollyPerPlayer': maxJollyPerPlayer,
      'jollyPrice': jollyPrice,
      'allowDoubleDown': allowDoubleDown,
      'allowGoldenTicket': allowGoldenTicket,
      'enableThemedRounds': enableThemedRounds,
      'specialMatchdays': specialMatchdays.map((e) => e.name).toList(),
      'autoElimination': autoElimination,
      'allowLateJoin': allowLateJoin,
      'maxLateJoinRound': maxLateJoinRound,
    };
  }
}

// Statistiche della lega
class LeagueStats {
  final int totalRounds;
  final int currentRound;
  final int activePlayers;
  final int eliminatedPlayers;
  final int totalJollyUsed;
  final int totalDoubleDownUsed;
  final String? currentLeader;
  final Map<String, int> playerStats;
  final List<String> winnersByRound;

  const LeagueStats({
    this.totalRounds = 38,
    this.currentRound = 0,
    this.activePlayers = 0,
    this.eliminatedPlayers = 0,
    this.totalJollyUsed = 0,
    this.totalDoubleDownUsed = 0,
    this.currentLeader,
    this.playerStats = const {},
    this.winnersByRound = const [],
  });

  factory LeagueStats.fromJson(Map<String, dynamic> json) {
    return LeagueStats(
      totalRounds: json['totalRounds'] ?? 38,
      currentRound: json['currentRound'] ?? 0,
      activePlayers: json['activePlayers'] ?? 0,
      eliminatedPlayers: json['eliminatedPlayers'] ?? 0,
      totalJollyUsed: json['totalJollyUsed'] ?? 0,
      totalDoubleDownUsed: json['totalDoubleDownUsed'] ?? 0,
      currentLeader: json['currentLeader'],
      playerStats: Map<String, int>.from(json['playerStats'] ?? {}),
      winnersByRound: List<String>.from(json['winnersByRound'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRounds': totalRounds,
      'currentRound': currentRound,
      'activePlayers': activePlayers,
      'eliminatedPlayers': eliminatedPlayers,
      'totalJollyUsed': totalJollyUsed,
      'totalDoubleDownUsed': totalDoubleDownUsed,
      'currentLeader': currentLeader,
      'playerStats': playerStats,
      'winnersByRound': winnersByRound,
    };
  }

  // Calcoli derivati
  double get eliminationRate {
    final total = activePlayers + eliminatedPlayers;
    return total > 0 ? (eliminatedPlayers / total) * 100 : 0.0;
  }

  double get averageJollyPerPlayer {
    return activePlayers > 0 ? totalJollyUsed / activePlayers : 0.0;
  }

  bool get isNearEnd => currentRound >= (totalRounds * 0.8); // Ultime 20% delle giornate
}

// Modello per partecipante della lega
class LeagueParticipant {
  final String userId;
  final String displayName;
  final String? email;
  final DateTime joinedAt;
  final bool isActive;
  final bool isAdmin;
  final int jollyLeft;
  final int jollyUsed;
  final bool hasGoldenTicket;
  final List<String> teamsUsed;
  final int currentStreak;
  final int longestStreak;
  final int totalWins;
  final DateTime? lastPickDate;
  final DateTime? eliminatedAt;
  final String? eliminatedReason;

  LeagueParticipant({
    required this.userId,
    required this.displayName,
    this.email,
    required this.joinedAt,
    this.isActive = true,
    this.isAdmin = false,
    this.jollyLeft = 0,
    this.jollyUsed = 0,
    this.hasGoldenTicket = false,
    this.teamsUsed = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalWins = 0,
    this.lastPickDate,
    this.eliminatedAt,
    this.eliminatedReason,
  });

  factory LeagueParticipant.fromJson(Map<String, dynamic> json) {
    return LeagueParticipant(
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'],
      joinedAt: (json['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      isAdmin: json['isAdmin'] ?? false,
      jollyLeft: json['jollyLeft'] ?? 0,
      jollyUsed: json['jollyUsed'] ?? 0,
      hasGoldenTicket: json['hasGoldenTicket'] ?? false,
      teamsUsed: List<String>.from(json['teamsUsed'] ?? []),
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalWins: json['totalWins'] ?? 0,
      lastPickDate: (json['lastPickDate'] as Timestamp?)?.toDate(),
      eliminatedAt: (json['eliminatedAt'] as Timestamp?)?.toDate(),
      eliminatedReason: json['eliminatedReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isActive': isActive,
      'isAdmin': isAdmin,
      'jollyLeft': jollyLeft,
      'jollyUsed': jollyUsed,
      'hasGoldenTicket': hasGoldenTicket,
      'teamsUsed': teamsUsed,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalWins': totalWins,
      'lastPickDate': lastPickDate != null ? Timestamp.fromDate(lastPickDate!) : null,
      'eliminatedAt': eliminatedAt != null ? Timestamp.fromDate(eliminatedAt!) : null,
      'eliminatedReason': eliminatedReason,
    };
  }
}

// Modello per scelta avanzata (estende Pick)
class AdvancedPick {
  final String id;
  final int round;
  final String userId;
  final String leagueId;
  final List<String> teams; // Per supportare scelta doppia
  final bool isDoubleDown;
  final bool usedJolly;
  final bool usedGoldenTicket;
  final PickResult result;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final String? notes;
  final Map<String, double>? teamOdds;

  AdvancedPick({
    required this.id,
    required this.round,
    required this.userId,
    required this.leagueId,
    required this.teams,
    this.isDoubleDown = false,
    this.usedJolly = false,
    this.usedGoldenTicket = false,
    this.result = PickResult.pending,
    required this.createdAt,
    this.submittedAt,
    this.notes,
    this.teamOdds,
  });

  factory AdvancedPick.fromJson(Map<String, dynamic> json) {
    return AdvancedPick(
      id: json['id'] ?? '',
      round: json['round'] ?? 0,
      userId: json['userId'] ?? '',
      leagueId: json['leagueId'] ?? '',
      teams: List<String>.from(json['teams'] ?? []),
      isDoubleDown: json['isDoubleDown'] ?? false,
      usedJolly: json['usedJolly'] ?? false,
      usedGoldenTicket: json['usedGoldenTicket'] ?? false,
      result: PickResult.values.firstWhere(
        (e) => e.name == json['result'],
        orElse: () => PickResult.pending,
      ),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      submittedAt: (json['submittedAt'] as Timestamp?)?.toDate(),
      notes: json['notes'],
      teamOdds: json['teamOdds'] != null 
        ? Map<String, double>.from(json['teamOdds'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'round': round,
      'userId': userId,
      'leagueId': leagueId,
      'teams': teams,
      'isDoubleDown': isDoubleDown,
      'usedJolly': usedJolly,
      'usedGoldenTicket': usedGoldenTicket,
      'result': result.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'notes': notes,
      'teamOdds': teamOdds,
    };
  }

  // Getters di utilità
  bool get isSinglePick => teams.length == 1;
  bool get isMultiplePick => teams.length > 1;
  bool get survived => result == PickResult.win || (usedJolly && result != PickResult.win);
  String get primaryTeam => teams.isNotEmpty ? teams.first : '';
}

// Risultati della giornata per la lega
enum PickResult {
  pending,    // In attesa del risultato
  win,        // Vittoria
  loss,       // Sconfitta  
  draw,       // Pareggio
}

// Estensioni di utilità
extension LeagueExtensions on LastManStandingLeague {
  String generateInviteCode() {
    // Genera codice invito univoco
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = (name + creatorId + timestamp.toString()).hashCode.abs();
    return 'LMS${hash.toString().substring(0, 6).toUpperCase()}';
  }

  bool canUserJoin(String userId) {
    return !participants.contains(userId) && 
           canJoin && 
           (allowLateJoin || !hasStarted);
  }

  bool get allowLateJoin => settings.allowLateJoin;
}

extension ParticipantExtensions on LeagueParticipant {
  bool get isEliminated => !isActive && eliminatedAt != null;
  bool get canUseJolly => jollyLeft > 0;
  
  String get statusDescription {
    if (isEliminated) return 'Eliminato';
    if (!isActive) return 'Inattivo';
    return 'Attivo';
  }
}