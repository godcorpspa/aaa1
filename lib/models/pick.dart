import 'package:cloud_firestore/cloud_firestore.dart';

enum PickResult {
  pending,    // In attesa del risultato
  win,        // Vittoria
  loss,       // Sconfitta
  draw,       // Pareggio
}

enum PickType {
  normal,     // Scelta normale
  doubleDown, // Scelta doppia
  themed,     // Giornata a tema
}

class Pick {
  final int giornata;
  final String team;
  final bool usedJolly;
  final PickResult result;
  final PickType type;
  final DateTime createdAt;
  final String? notes;
  final double? odds; // Quote della squadra scelta

  Pick({
    required this.giornata,
    required this.team,
    this.usedJolly = false,
    this.result = PickResult.pending,
    this.type = PickType.normal,
    DateTime? createdAt,
    this.notes,
    this.odds,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Pick.fromJson(Map<String, dynamic> json) {
    return Pick(
      giornata: (json['giornata'] ?? 0) as int,
      team: (json['team'] ?? '') as String,
      usedJolly: (json['usedJolly'] ?? false) as bool,
      result: PickResult.values.firstWhere(
        (e) => e.name == json['result'],
        orElse: () => PickResult.pending,
      ),
      type: PickType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PickType.normal,
      ),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: json['notes'] as String?,
      odds: (json['odds'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'giornata': giornata,
      'team': team,
      'usedJolly': usedJolly,
      'result': result.name,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
      'odds': odds,
    };
  }

  /// Verifica se la scelta è stata una vittoria
  bool get isWin => result == PickResult.win;

  /// Verifica se la scelta è stata una sconfitta
  bool get isLoss => result == PickResult.loss;

  /// Verifica se la scelta è stata un pareggio
  bool get isDraw => result == PickResult.draw;

  /// Verifica se il risultato è ancora in sospeso
  bool get isPending => result == PickResult.pending;

  /// Verifica se l'utente è sopravvissuto (vittoria o pareggio con jolly)
  bool get survived => isWin || (usedJolly && (isLoss || isDraw));

  /// Verifica se è una scelta ad alto rischio (quote basse)
  bool get isHighRiskPick => odds != null && odds! >= 3.0;

  /// Verifica se è una scelta conservativa (quote alte)
  bool get isConservativePick => odds != null && odds! <= 1.5;

  /// Restituisce una descrizione del risultato
  String get resultDescription {
    switch (result) {
      case PickResult.win:
        return usedJolly ? 'Vittoria (con Jolly)' : 'Vittoria';
      case PickResult.loss:
        return usedJolly ? 'Salvato (Jolly usato)' : 'Eliminato';
      case PickResult.draw:
        return usedJolly ? 'Salvato (Jolly usato)' : 'Eliminato';
      case PickResult.pending:
        return 'In attesa...';
    }
  }

  /// Restituisce il colore associato al risultato
  String get resultColorHex {
    if (usedJolly && (isLoss || isDraw)) return '#FFA726'; // Arancione per jolly usato
    switch (result) {
      case PickResult.win:
        return '#4CAF50'; // Verde
      case PickResult.loss:
      case PickResult.draw:
        return '#F44336'; // Rosso
      case PickResult.pending:
        return '#9E9E9E'; // Grigio
    }
  }

  /// Restituisce l'icona associata al risultato
  String get resultIcon {
    if (usedJolly && (isLoss || isDraw)) return '🛡️';
    switch (result) {
      case PickResult.win:
        return '✅';
      case PickResult.loss:
      case PickResult.draw:
        return '❌';
      case PickResult.pending:
        return '⏳';
    }
  }

  /// Verifica se due scelte sono uguali
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pick &&
        other.giornata == giornata &&
        other.team == team &&
        other.usedJolly == usedJolly &&
        other.result == result &&
        other.type == type &&
        other.notes == notes &&
        other.odds == odds;
  }

  @override
  int get hashCode {
    return Object.hash(
      giornata,
      team,
      usedJolly,
      result,
      type,
      notes,
      odds,
    );
  }

  /// Crea una copia con valori modificati
  Pick copyWith({
    int? giornata,
    String? team,
    bool? usedJolly,
    PickResult? result,
    PickType? type,
    DateTime? createdAt,
    String? notes,
    double? odds,
  }) {
    return Pick(
      giornata: giornata ?? this.giornata,
      team: team ?? this.team,
      usedJolly: usedJolly ?? this.usedJolly,
      result: result ?? this.result,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      odds: odds ?? this.odds,
    );
  }

  @override
  String toString() {
    return 'Pick('
        'giornata: $giornata, '
        'team: $team, '
        'result: ${result.name}, '
        'usedJolly: $usedJolly, '
        'type: ${type.name}'
        ')';
  }
}

/// Estensione per facilitare operazioni su liste di Pick
extension PickListExtensions on List<Pick> {
  /// Filtra le scelte per risultato
  List<Pick> whereResult(PickResult result) {
    return where((pick) => pick.result == result).toList();
  }

  /// Conta le vittorie
  int get winsCount => whereResult(PickResult.win).length;

  /// Conta le sconfitte
  int get lossesCount => 
      whereResult(PickResult.loss).length + whereResult(PickResult.draw).length;

  /// Conta i jolly usati
  int get jolliesUsedCount => where((pick) => pick.usedJolly).length;

  /// Calcola la streak corrente di vittorie
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

  /// Calcola la streak più lunga
  int get longestStreak {
    if (isEmpty) return 0;
    
    int maxStreak = 0;
    int currentStreak = 0;
    
    for (final pick in this) {
      if (pick.survived) {
        currentStreak++;
        maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
      } else {
        currentStreak = 0;
      }
    }
    
    return maxStreak;
  }

  /// Restituisce la percentuale di successo
  double get successRate {
    if (isEmpty) return 0.0;
    final completed = where((pick) => !pick.isPending).toList();
    if (completed.isEmpty) return 0.0;
    
    final successes = completed.where((pick) => pick.survived).length;
    return (successes / completed.length) * 100;
  }

  /// Restituisce le squadre più utilizzate
  Map<String, int> get teamUsageStats {
    final Map<String, int> stats = {};
    for (final pick in this) {
      stats[pick.team] = (stats[pick.team] ?? 0) + 1;
    }
    return Map.fromEntries(
      stats.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
    );
  }
}