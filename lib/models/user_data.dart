import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  final int jollyLeft;
  final List<String> teamsUsed;
  final bool isActive;
  final int currentStreak;
  final int totalWins;
  final DateTime? lastPickDate;
  final DateTime? lastJollyUsed;
  final String displayName;
  final String? email;

  UserData({
    required this.jollyLeft,
    required this.teamsUsed,
    this.isActive = true,
    this.currentStreak = 0,
    this.totalWins = 0,
    this.lastPickDate,
    this.lastJollyUsed,
    this.displayName = 'Utente',
    this.email,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      jollyLeft: (json['jollyLeft'] ?? 0) as int,
      teamsUsed: List<String>.from(json['teamsUsed'] ?? []),
      isActive: (json['isActive'] ?? true) as bool,
      currentStreak: (json['currentStreak'] ?? 0) as int,
      totalWins: (json['totalWins'] ?? 0) as int,
      lastPickDate: (json['lastPickDate'] as Timestamp?)?.toDate(),
      lastJollyUsed: (json['lastJollyUsed'] as Timestamp?)?.toDate(),
      displayName: (json['displayName'] ?? 'Utente') as String,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jollyLeft': jollyLeft,
      'teamsUsed': teamsUsed,
      'isActive': isActive,
      'currentStreak': currentStreak,
      'totalWins': totalWins,
      'lastPickDate': lastPickDate != null ? Timestamp.fromDate(lastPickDate!) : null,
      'lastJollyUsed': lastJollyUsed != null ? Timestamp.fromDate(lastJollyUsed!) : null,
      'displayName': displayName,
      'email': email,
    };
  }

  /// Verifica se l'utente può acquistare un jolly
  bool get canPurchaseJolly => jollyLeft < 3;

  /// Verifica se l'utente ha jolly disponibili
  bool get hasJollyAvailable => jollyLeft > 0;

  /// Verifica se una squadra è già stata utilizzata
  bool hasUsedTeam(String team) => teamsUsed.contains(team);

  /// Restituisce il numero di squadre rimanenti utilizzabili
  int getRemainingTeams(List<String> allTeams) {
    return allTeams.where((team) => !teamsUsed.contains(team)).length;
  }

  /// Restituisce le squadre ancora utilizzabili
  List<String> getAvailableTeams(List<String> allTeams) {
    return allTeams.where((team) => !teamsUsed.contains(team)).toList();
  }

  /// Verifica se l'utente è considerato "esperto" (più di 5 vittorie)
  bool get isExpertPlayer => totalWins >= 5;

  /// Restituisce il ranking basato sulla streak corrente
  String get streakRank {
    if (currentStreak >= 10) return 'Leggenda';
    if (currentStreak >= 7) return 'Esperto';
    if (currentStreak >= 5) return 'Veterano';
    if (currentStreak >= 3) return 'Promettente';
    return 'Principiante';
  }

  /// Verifica se l'utente ha fatto una scelta di recente
  bool get hasRecentActivity {
    if (lastPickDate == null) return false;
    final daysSinceLastPick = DateTime.now().difference(lastPickDate!).inDays;
    return daysSinceLastPick <= 7;
  }

  /// Crea una copia con valori modificati
  UserData copyWith({
    int? jollyLeft,
    List<String>? teamsUsed,
    bool? isActive,
    int? currentStreak,
    int? totalWins,
    DateTime? lastPickDate,
    DateTime? lastJollyUsed,
    String? displayName,
    String? email,
  }) {
    return UserData(
      jollyLeft: jollyLeft ?? this.jollyLeft,
      teamsUsed: teamsUsed ?? this.teamsUsed,
      isActive: isActive ?? this.isActive,
      currentStreak: currentStreak ?? this.currentStreak,
      totalWins: totalWins ?? this.totalWins,
      lastPickDate: lastPickDate ?? this.lastPickDate,
      lastJollyUsed: lastJollyUsed ?? this.lastJollyUsed,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserData &&
        other.jollyLeft == jollyLeft &&
        other.isActive == isActive &&
        other.currentStreak == currentStreak &&
        other.totalWins == totalWins &&
        other.displayName == displayName &&
        other.email == email &&
        _listEquals(other.teamsUsed, teamsUsed);
  }

  @override
  int get hashCode {
    return Object.hash(
      jollyLeft,
      teamsUsed,
      isActive,
      currentStreak,
      totalWins,
      displayName,
      email,
    );
  }

  @override
  String toString() {
    return 'UserData('
        'jollyLeft: $jollyLeft, '
        'teamsUsed: ${teamsUsed.length}, '
        'isActive: $isActive, '
        'currentStreak: $currentStreak, '
        'totalWins: $totalWins, '
        'displayName: $displayName'
        ')';
  }
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