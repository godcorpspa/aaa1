import 'package:cloud_firestore/cloud_firestore.dart';

enum PickResult {
  pending,
  win,
  loss,
  draw,
}

enum PickType {
  normal,
  doubleChoice,
}

class Pick {
  final int giornata;
  final String team;
  final String? secondTeam;
  final bool usedGoldTicket;
  final PickResult result;
  final PickResult? secondTeamResult;
  final PickType type;
  final DateTime createdAt;

  Pick({
    required this.giornata,
    required this.team,
    this.secondTeam,
    this.usedGoldTicket = false,
    this.result = PickResult.pending,
    this.secondTeamResult,
    this.type = PickType.normal,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Pick.fromJson(Map<String, dynamic> json) {
    return Pick(
      giornata: (json['giornata'] ?? 0) as int,
      team: (json['team'] ?? '') as String,
      secondTeam: json['secondTeam'] as String?,
      usedGoldTicket: (json['usedGoldTicket'] ?? false) as bool,
      result: PickResult.values.firstWhere(
        (e) => e.name == json['result'],
        orElse: () => PickResult.pending,
      ),
      secondTeamResult: json['secondTeamResult'] != null
          ? PickResult.values.firstWhere(
              (e) => e.name == json['secondTeamResult'],
              orElse: () => PickResult.pending,
            )
          : null,
      type: PickType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PickType.normal,
      ),
      createdAt:
          (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'giornata': giornata,
      'team': team,
      'secondTeam': secondTeam,
      'usedGoldTicket': usedGoldTicket,
      'result': result.name,
      'secondTeamResult': secondTeamResult?.name,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isWin => result == PickResult.win;
  bool get isLoss => result == PickResult.loss;
  bool get isDraw => result == PickResult.draw;
  bool get isPending => result == PickResult.pending;
  bool get isDoubleChoice => type == PickType.doubleChoice;

  /// Per la Double Choice, entrambe le squadre devono vincere.
  /// Se si usa il Gold Ticket, si sopravvive automaticamente.
  bool get survived {
    if (usedGoldTicket) return true;
    if (isDoubleChoice) {
      return result == PickResult.win &&
          secondTeamResult == PickResult.win;
    }
    return isWin;
  }

  /// La Double Choice con entrambe vittorie genera un Gold Ticket
  bool get earnsGoldTicket {
    return isDoubleChoice &&
        result == PickResult.win &&
        secondTeamResult == PickResult.win;
  }

  String get resultDescription {
    if (usedGoldTicket) return 'Gold Ticket usato';
    if (isDoubleChoice) {
      if (isPending) return 'In attesa...';
      if (earnsGoldTicket) return 'Doppia vittoria! Gold Ticket guadagnato';
      return 'Eliminato (doppia scelta fallita)';
    }
    switch (result) {
      case PickResult.win:
        return 'Vittoria';
      case PickResult.loss:
        return 'Eliminato';
      case PickResult.draw:
        return 'Eliminato (pareggio)';
      case PickResult.pending:
        return 'In attesa...';
    }
  }

  Pick copyWith({
    int? giornata,
    String? team,
    String? secondTeam,
    bool? usedGoldTicket,
    PickResult? result,
    PickResult? secondTeamResult,
    PickType? type,
    DateTime? createdAt,
  }) {
    return Pick(
      giornata: giornata ?? this.giornata,
      team: team ?? this.team,
      secondTeam: secondTeam ?? this.secondTeam,
      usedGoldTicket: usedGoldTicket ?? this.usedGoldTicket,
      result: result ?? this.result,
      secondTeamResult: secondTeamResult ?? this.secondTeamResult,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pick &&
        other.giornata == giornata &&
        other.team == team &&
        other.secondTeam == secondTeam &&
        other.usedGoldTicket == usedGoldTicket &&
        other.result == result &&
        other.secondTeamResult == secondTeamResult &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(
        giornata, team, secondTeam, usedGoldTicket,
        result, secondTeamResult, type,
      );

  @override
  String toString() =>
      'Pick(giornata: $giornata, team: $team, result: ${result.name}, type: ${type.name})';
}

extension PickListExtensions on List<Pick> {
  List<Pick> whereResult(PickResult result) =>
      where((p) => p.result == result).toList();

  int get winsCount => where((p) => p.survived).length;

  int get lossesCount => where((p) => !p.survived && !p.isPending).length;

  int get goldTicketsEarned => where((p) => p.earnsGoldTicket).length;

  int get goldTicketsUsed => where((p) => p.usedGoldTicket).length;

  int get currentStreak {
    if (isEmpty) return 0;
    int streak = 0;
    for (int i = length - 1; i >= 0; i--) {
      if (this[i].survived) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int get longestStreak {
    if (isEmpty) return 0;
    int maxStreak = 0;
    int current = 0;
    for (final pick in this) {
      if (pick.survived) {
        current++;
        if (current > maxStreak) maxStreak = current;
      } else {
        current = 0;
      }
    }
    return maxStreak;
  }

  double get successRate {
    final completed = where((p) => !p.isPending).toList();
    if (completed.isEmpty) return 0.0;
    final successes = completed.where((p) => p.survived).length;
    return (successes / completed.length) * 100;
  }

  Map<String, int> get teamUsageStats {
    final Map<String, int> stats = {};
    for (final pick in this) {
      stats[pick.team] = (stats[pick.team] ?? 0) + 1;
      if (pick.secondTeam != null) {
        stats[pick.secondTeam!] = (stats[pick.secondTeam!] ?? 0) + 1;
      }
    }
    return Map.fromEntries(
      stats.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }
}
