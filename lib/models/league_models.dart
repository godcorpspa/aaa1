import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'pick.dart';

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

  Team({required this.id, required this.name, required this.logo});

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      logo: json['logo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'logo': logo};
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
      date: DateTime.parse(
          fixture['date'] ?? DateTime.now().toIso8601String()),
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
  bool get isPostponed => status == MatchStatus.postponed;
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
        return minute != null ? "$minute'" : 'LIVE';
      case MatchStatus.finished:
        return 'FT';
      case MatchStatus.postponed:
        return 'RINV';
      case MatchStatus.cancelled:
        return 'CANC';
    }
  }

  /// Verifica se una squadra ha vinto questa partita
  PickResult resultForTeam(String teamName) {
    if (!isFinished) return PickResult.pending;
    if (homeScore == null || awayScore == null) return PickResult.pending;

    final isHome = homeTeam.name == teamName;
    final isAway = awayTeam.name == teamName;
    if (!isHome && !isAway) return PickResult.pending;

    if (homeScore == awayScore) return PickResult.draw;
    if (isHome) {
      return homeScore! > awayScore! ? PickResult.win : PickResult.loss;
    }
    return awayScore! > homeScore! ? PickResult.win : PickResult.loss;
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

  /// Squadre le cui partite sono state rinviate prima dell'inizio della giornata
  List<String> get unavailableTeams {
    return matches
        .where((m) => m.isPostponed && m.date.isBefore(startDate))
        .expand((m) => [m.homeTeam.name, m.awayTeam.name])
        .toList();
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

enum LeagueStatus {
  waiting,
  active,
  completed,
  cancelled,
}

class LastManStandingLeague {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;
  final bool isPrivate;
  final bool requirePassword;
  final String? passwordHash;
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

  LastManStandingLeague({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    this.isPrivate = false,
    this.requirePassword = false,
    this.passwordHash,
    this.maxParticipants = 100,
    this.currentParticipants = 0,
    this.participants = const [],
    this.admins = const [],
    this.status = LeagueStatus.waiting,
    this.settings = const LeagueSettings(),
    this.inviteCode,
    this.startDate,
    this.endDate,
    this.stats = const LeagueStats(),
  });

  factory LastManStandingLeague.fromJson(Map<String, dynamic> json) {
    return LastManStandingLeague(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      creatorId: json['creatorId'] ?? '',
      creatorName: json['creatorName'] ?? '',
      createdAt:
          (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPrivate: json['isPrivate'] ?? false,
      requirePassword: json['requirePassword'] ?? false,
      passwordHash: json['passwordHash'] ?? json['password'],
      maxParticipants: json['maxParticipants'] ?? 100,
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
      'passwordHash': passwordHash,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'participants': participants,
      'admins': admins,
      'status': status.name,
      'settings': settings.toJson(),
      'inviteCode': inviteCode,
      'startDate':
          startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'stats': stats.toJson(),
    };
  }

  bool get isFull => currentParticipants >= maxParticipants;
  bool get isActive => status == LeagueStatus.active;
  bool get canJoin => !isFull && status == LeagueStatus.waiting;
  bool isCreator(String userId) => creatorId == userId;
  bool isAdmin(String userId) =>
      admins.contains(userId) || creatorId == userId;
  bool get hasStarted =>
      startDate != null && DateTime.now().isAfter(startDate!);

  LastManStandingLeague copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    String? creatorName,
    DateTime? createdAt,
    bool? isPrivate,
    bool? requirePassword,
    String? passwordHash,
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
      passwordHash: passwordHash ?? this.passwordHash,
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
    );
  }

  static String generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return 'LMS-${List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join()}';
  }
}

class LeagueSettings {
  final bool allowDoubleChoice;
  final bool allowGoldTicket;
  final bool autoElimination;
  final bool allowLateJoin;
  final int maxLateJoinRound;

  const LeagueSettings({
    this.allowDoubleChoice = true,
    this.allowGoldTicket = true,
    this.autoElimination = true,
    this.allowLateJoin = false,
    this.maxLateJoinRound = 3,
  });

  factory LeagueSettings.fromJson(Map<String, dynamic> json) {
    return LeagueSettings(
      allowDoubleChoice: json['allowDoubleChoice'] ?? json['allowDoubleDown'] ?? true,
      allowGoldTicket: json['allowGoldTicket'] ?? json['allowGoldenTicket'] ?? true,
      autoElimination: json['autoElimination'] ?? true,
      allowLateJoin: json['allowLateJoin'] ?? false,
      maxLateJoinRound: json['maxLateJoinRound'] ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowDoubleChoice': allowDoubleChoice,
      'allowGoldTicket': allowGoldTicket,
      'autoElimination': autoElimination,
      'allowLateJoin': allowLateJoin,
      'maxLateJoinRound': maxLateJoinRound,
    };
  }
}

class LeagueStats {
  final int totalRounds;
  final int currentRound;
  final int activePlayers;
  final int eliminatedPlayers;
  final int totalGoldTicketsUsed;
  final int totalDoubleChoicesUsed;
  final String? currentLeader;

  const LeagueStats({
    this.totalRounds = 38,
    this.currentRound = 0,
    this.activePlayers = 0,
    this.eliminatedPlayers = 0,
    this.totalGoldTicketsUsed = 0,
    this.totalDoubleChoicesUsed = 0,
    this.currentLeader,
  });

  factory LeagueStats.fromJson(Map<String, dynamic> json) {
    return LeagueStats(
      totalRounds: json['totalRounds'] ?? 38,
      currentRound: json['currentRound'] ?? 0,
      activePlayers: json['activePlayers'] ?? 0,
      eliminatedPlayers: json['eliminatedPlayers'] ?? 0,
      totalGoldTicketsUsed: json['totalGoldTicketsUsed'] ?? json['totalJollyUsed'] ?? 0,
      totalDoubleChoicesUsed: json['totalDoubleChoicesUsed'] ?? json['totalDoubleDownUsed'] ?? 0,
      currentLeader: json['currentLeader'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRounds': totalRounds,
      'currentRound': currentRound,
      'activePlayers': activePlayers,
      'eliminatedPlayers': eliminatedPlayers,
      'totalGoldTicketsUsed': totalGoldTicketsUsed,
      'totalDoubleChoicesUsed': totalDoubleChoicesUsed,
      'currentLeader': currentLeader,
    };
  }

  double get eliminationRate {
    final total = activePlayers + eliminatedPlayers;
    return total > 0 ? (eliminatedPlayers / total) * 100 : 0.0;
  }
}

class LeagueParticipant {
  final String userId;
  final String displayName;
  final String? email;
  final DateTime joinedAt;
  final bool isActive;
  final bool isAdmin;
  final int goldTickets;
  final List<String> teamsUsed;
  final int currentStreak;
  final int longestStreak;
  final int totalSurvivals;
  final DateTime? lastPickDate;
  final DateTime? eliminatedAt;
  final int? eliminatedAtRound;

  LeagueParticipant({
    required this.userId,
    required this.displayName,
    this.email,
    required this.joinedAt,
    this.isActive = true,
    this.isAdmin = false,
    this.goldTickets = 0,
    this.teamsUsed = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalSurvivals = 0,
    this.lastPickDate,
    this.eliminatedAt,
    this.eliminatedAtRound,
  });

  factory LeagueParticipant.fromJson(Map<String, dynamic> json) {
    return LeagueParticipant(
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'],
      joinedAt:
          (json['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      isAdmin: json['isAdmin'] ?? false,
      goldTickets: json['goldTickets'] ?? json['jollyLeft'] ?? 0,
      teamsUsed: List<String>.from(json['teamsUsed'] ?? []),
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalSurvivals: json['totalSurvivals'] ?? json['totalWins'] ?? 0,
      lastPickDate: (json['lastPickDate'] as Timestamp?)?.toDate(),
      eliminatedAt: (json['eliminatedAt'] as Timestamp?)?.toDate(),
      eliminatedAtRound: json['eliminatedAtRound'],
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
      'goldTickets': goldTickets,
      'teamsUsed': teamsUsed,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalSurvivals': totalSurvivals,
      'lastPickDate':
          lastPickDate != null ? Timestamp.fromDate(lastPickDate!) : null,
      'eliminatedAt':
          eliminatedAt != null ? Timestamp.fromDate(eliminatedAt!) : null,
      'eliminatedAtRound': eliminatedAtRound,
    };
  }

  bool get isEliminated => !isActive && eliminatedAt != null;
  bool get hasGoldTicket => goldTickets > 0;

  String get statusDescription {
    if (isEliminated) return 'Eliminato';
    if (!isActive) return 'Inattivo';
    return 'Attivo';
  }
}
