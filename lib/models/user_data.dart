import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserData {
  final int goldTickets;
  final List<String> teamsUsed;
  final bool isActive;
  final int currentStreak;
  final int totalSurvivals;
  final DateTime? lastPickDate;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final int? eliminatedAtRound;

  UserData({
    this.goldTickets = 0,
    required this.teamsUsed,
    this.isActive = true,
    this.currentStreak = 0,
    this.totalSurvivals = 0,
    this.lastPickDate,
    this.displayName = 'Utente',
    this.email,
    this.photoUrl,
    this.eliminatedAtRound,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      goldTickets: (json['goldTickets'] ?? json['jollyLeft'] ?? 0) as int,
      teamsUsed: List<String>.from(json['teamsUsed'] ?? []),
      isActive: (json['isActive'] ?? true) as bool,
      currentStreak: (json['currentStreak'] ?? 0) as int,
      totalSurvivals: (json['totalSurvivals'] ?? json['totalWins'] ?? 0) as int,
      lastPickDate: (json['lastPickDate'] as Timestamp?)?.toDate(),
      displayName: (json['displayName'] ?? 'Utente') as String,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      eliminatedAtRound: json['eliminatedAtRound'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goldTickets': goldTickets,
      'teamsUsed': teamsUsed,
      'isActive': isActive,
      'currentStreak': currentStreak,
      'totalSurvivals': totalSurvivals,
      'lastPickDate':
          lastPickDate != null ? Timestamp.fromDate(lastPickDate!) : null,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'eliminatedAtRound': eliminatedAtRound,
    };
  }

  bool get hasGoldTicket => goldTickets > 0;
  bool get isEliminated => !isActive;
  bool hasUsedTeam(String team) => teamsUsed.contains(team);

  int getRemainingTeams(List<String> allTeams) =>
      allTeams.where((t) => !teamsUsed.contains(t)).length;

  List<String> getAvailableTeams(List<String> allTeams) =>
      allTeams.where((t) => !teamsUsed.contains(t)).toList();

  /// Auto-assign: prima squadra disponibile in ordine alfabetico
  String? getAutoAssignTeam(List<String> allTeams) {
    final available = getAvailableTeams(allTeams)..sort();
    return available.isNotEmpty ? available.first : null;
  }

  UserData copyWith({
    int? goldTickets,
    List<String>? teamsUsed,
    bool? isActive,
    int? currentStreak,
    int? totalSurvivals,
    DateTime? lastPickDate,
    String? displayName,
    String? email,
    String? photoUrl,
    int? eliminatedAtRound,
  }) {
    return UserData(
      goldTickets: goldTickets ?? this.goldTickets,
      teamsUsed: teamsUsed ?? this.teamsUsed,
      isActive: isActive ?? this.isActive,
      currentStreak: currentStreak ?? this.currentStreak,
      totalSurvivals: totalSurvivals ?? this.totalSurvivals,
      lastPickDate: lastPickDate ?? this.lastPickDate,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      eliminatedAtRound: eliminatedAtRound ?? this.eliminatedAtRound,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserData &&
        other.goldTickets == goldTickets &&
        other.isActive == isActive &&
        other.currentStreak == currentStreak &&
        other.totalSurvivals == totalSurvivals &&
        other.displayName == displayName &&
        other.email == email &&
        listEquals(other.teamsUsed, teamsUsed);
  }

  @override
  int get hashCode => Object.hash(
        goldTickets, isActive, currentStreak,
        totalSurvivals, displayName, email,
      );

  @override
  String toString() =>
      'UserData(displayName: $displayName, active: $isActive, streak: $currentStreak, goldTickets: $goldTickets)';
}
