import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchdayType {
  normal,      // Giornata normale
  themed,      // Giornata a tema (es. solo squadre in casa)
  doubleDown,  // Giornata double down disponibile
  playoff,     // Giornata playoff
  final_,      // Giornata finale
}

enum MatchdayStatus {
  upcoming,    // Prossima giornata
  active,      // Giornata in corso (scelte aperte)
  closed,      // Scelte chiuse, partite in corso
  completed,   // Giornata completata
}

class Matchday {
  final int giornata;
  final DateTime deadline;
  final List<String> validTeams;
  final MatchdayType type;
  final MatchdayStatus status;
  final String? themeDescription;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, double>? teamOdds;
  final int participantsCount;
  final int activePlayers;
  final bool doubleDownAvailable;
  final String? specialRules;

  Matchday({
    required this.giornata,
    required this.deadline,
    required this.validTeams,
    this.type = MatchdayType.normal,
    this.status = MatchdayStatus.upcoming,
    this.themeDescription,
    this.startDate,
    this.endDate,
    this.teamOdds,
    this.participantsCount = 0,
    this.activePlayers = 0,
    this.doubleDownAvailable = false,
    this.specialRules,
  });

  factory Matchday.fromJson(Map<String, dynamic> json) {
    return Matchday(
      giornata: (json['giornata'] ?? 0) as int,
      deadline: (json['deadline'] as Timestamp?)?.toDate() ??
          DateTime.now().subtract(const Duration(days: 1)),
      validTeams: List<String>.from(json['validTeams'] ?? []),
      type: MatchdayType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MatchdayType.normal,
      ),
      status: MatchdayStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MatchdayStatus.upcoming,
      ),
      themeDescription: json['themeDescription'] as String?,
      startDate: (json['startDate'] as Timestamp?)?.toDate(),
      endDate: (json['endDate'] as Timestamp?)?.toDate(),
      teamOdds: json['teamOdds'] != null 
        ? Map<String, double>.from(
            (json['teamOdds'] as Map).map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble())
            )
          )
        : null,
      participantsCount: (json['participantsCount'] ?? 0) as int,
      activePlayers: (json['activePlayers'] ?? 0) as int,
      doubleDownAvailable: (json['doubleDownAvailable'] ?? false) as bool,
      specialRules: json['specialRules'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'giornata': giornata,
      'deadline': Timestamp.fromDate(deadline),
      'validTeams': validTeams,
      'type': type.name,
      'status': status.name,
      'themeDescription': themeDescription,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'teamOdds': teamOdds,
      'participantsCount': participantsCount,
      'activePlayers': activePlayers,
      'doubleDownAvailable': doubleDownAvailable,
      'specialRules': specialRules,
    };
  }

  /// Verifica se è una giornata a tema
  bool get isThemed => type == MatchdayType.themed && validTeams.isNotEmpty;

  /// Verifica se le scelte sono ancora aperte
  bool get isOpen => DateTime.now().isBefore(deadline) && status == MatchdayStatus.active;

  /// Verifica se la giornata è scaduta
  bool get isExpired => DateTime.now().isAfter(deadline);

  /// Verifica se è l'ultima giornata del campionato
  bool get isFinalMatchday => giornata == 38 || type == MatchdayType.final_;

  /// Verifica se è una giornata di playoff
  bool get isPlayoff => type == MatchdayType.playoff;

  /// Calcola il tempo rimanente fino alla scadenza
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(deadline)) return Duration.zero;
    return deadline.difference(now);
  }

  /// Restituisce una descrizione dello stato
  String get statusDescription {
    switch (status) {
      case MatchdayStatus.upcoming:
        return 'Prossima giornata';
      case MatchdayStatus.active:
        return isOpen ? 'Scelte aperte' : 'Scelte chiuse';
      case MatchdayStatus.closed:
        return 'Partite in corso';
      case MatchdayStatus.completed:
        return 'Completata';
    }
  }

  /// Restituisce il colore associato allo stato
  String get statusColorHex {
    switch (status) {
      case MatchdayStatus.upcoming:
        return '#9E9E9E'; // Grigio
      case MatchdayStatus.active:
        return isOpen ? '#4CAF50' : '#FF9800'; // Verde se aperte, arancione se chiuse
      case MatchdayStatus.closed:
        return '#2196F3'; // Blu
      case MatchdayStatus.completed:
        return '#607D8B'; // Grigio bluastro
    }
  }

  /// Restituisce la descrizione del tipo di giornata
  String get typeDescription {
    switch (type) {
      case MatchdayType.normal:
        return 'Giornata regolare';
      case MatchdayType.themed:
        return themeDescription ?? 'Giornata a tema';
      case MatchdayType.doubleDown:
        return 'Double Down disponibile';
      case MatchdayType.playoff:
        return 'Giornata Playoff';
      case MatchdayType.final_:
        return 'Giornata Finale';
    }
  }

  /// Verifica se una squadra è valida per questa giornata
  bool isTeamValid(String team) {
    if (validTeams.isEmpty) return true; // Nessuna restrizione
    return validTeams.contains(team);
  }

  /// Restituisce le quote di una squadra
  double? getTeamOdds(String team) {
    return teamOdds?[team];
  }

  /// Verifica se ci sono quote disponibili
  bool get hasOdds => teamOdds != null && teamOdds!.isNotEmpty;

  /// Restituisce le squadre ordinate per quote (dalle più basse alle più alte)
  List<String> get teamsSortedByOdds {
    if (!hasOdds) return validTeams;
    
    final teamsWithOdds = validTeams.where((team) => teamOdds!.containsKey(team)).toList();
    teamsWithOdds.sort((a, b) {
      final oddsA = teamOdds![a] ?? double.infinity;
      final oddsB = teamOdds![b] ?? double.infinity;
      return oddsA.compareTo(oddsB);
    });
    
    return teamsWithOdds;
  }

  /// Restituisce statistiche della giornata
  MatchdayStats get stats {
    return MatchdayStats(
      totalTeams: validTeams.length,
      participantsCount: participantsCount,
      activePlayers: activePlayers,
      eliminationRate: participantsCount > 0 
        ? ((participantsCount - activePlayers) / participantsCount) * 100 
        : 0.0,
      averageOdds: hasOdds 
        ? teamOdds!.values.reduce((a, b) => a + b) / teamOdds!.length
        : null,
    );
  }

  /// Valida i dati della giornata
  List<String> validate() {
    final errors = <String>[];
    
    if (giornata < 1 || giornata > 38) {
      errors.add('Numero giornata non valido: $giornata');
    }
    
    if (deadline.isBefore(DateTime.now().subtract(const Duration(days: 365)))) {
      errors.add('Data deadline non valida');
    }
    
    if (startDate != null && endDate != null && startDate!.isAfter(endDate!)) {
      errors.add('Data inizio posteriore alla data fine');
    }
    
    if (deadline.isAfter(startDate ?? DateTime.now().add(const Duration(days: 7)))) {
      errors.add('Deadline posteriore all\'inizio delle partite');
    }
    
    if (type == MatchdayType.themed && validTeams.isEmpty) {
      errors.add('Giornata a tema senza squadre valide');
    }
    
    if (participantsCount < 0 || activePlayers < 0) {
      errors.add('Contatori partecipanti non validi');
    }
    
    if (activePlayers > participantsCount) {
      errors.add('Giocatori attivi maggiori dei partecipanti totali');
    }
    
    return errors;
  }

  /// Verifica se la giornata è valida
  bool get isValid => validate().isEmpty;

  /// Crea una copia con valori modificati
  Matchday copyWith({
    int? giornata,
    DateTime? deadline,
    List<String>? validTeams,
    MatchdayType? type,
    MatchdayStatus? status,
    String? themeDescription,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, double>? teamOdds,
    int? participantsCount,
    int? activePlayers,
    bool? doubleDownAvailable,
    String? specialRules,
  }) {
    return Matchday(
      giornata: giornata ?? this.giornata,
      deadline: deadline ?? this.deadline,
      validTeams: validTeams ?? this.validTeams,
      type: type ?? this.type,
      status: status ?? this.status,
      themeDescription: themeDescription ?? this.themeDescription,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      teamOdds: teamOdds ?? this.teamOdds,
      participantsCount: participantsCount ?? this.participantsCount,
      activePlayers: activePlayers ?? this.activePlayers,
      doubleDownAvailable: doubleDownAvailable ?? this.doubleDownAvailable,
      specialRules: specialRules ?? this.specialRules,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Matchday &&
        other.giornata == giornata &&
        other.deadline == deadline &&
        other.type == type &&
        other.status == status &&
        _listEquals(other.validTeams, validTeams);
  }

  @override
  int get hashCode {
    return Object.hash(
      giornata,
      deadline,
      validTeams,
      type,
      status,
    );
  }

  @override
  String toString() {
    return 'Matchday('
        'giornata: $giornata, '
        'deadline: $deadline, '
        'type: ${type.name}, '
        'status: ${status.name}, '
        'validTeams: ${validTeams.length}, '
        'participants: $participantsCount'
        ')';
  }
}

/// Statistiche della giornata
class MatchdayStats {
  final int totalTeams;
  final int participantsCount;
  final int activePlayers;
  final double eliminationRate;
  final double? averageOdds;

  MatchdayStats({
    required this.totalTeams,
    required this.participantsCount,
    required this.activePlayers,
    required this.eliminationRate,
    this.averageOdds,
  });

  int get eliminatedPlayers => participantsCount - activePlayers;
  
  double get survivalRate => 100 - eliminationRate;
}

/// Utility per confrontare liste
bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  if (identical(a, b)) return true;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}