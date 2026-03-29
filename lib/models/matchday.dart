import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum MatchdayStatus {
  upcoming,
  active,
  closed,
  completed,
}

class Matchday {
  final int giornata;
  final DateTime deadline;
  final List<String> availableTeams;
  final MatchdayStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int participantsCount;
  final int activePlayers;
  final bool doubleChoiceAvailable;

  Matchday({
    required this.giornata,
    required this.deadline,
    required this.availableTeams,
    this.status = MatchdayStatus.upcoming,
    this.startDate,
    this.endDate,
    this.participantsCount = 0,
    this.activePlayers = 0,
    this.doubleChoiceAvailable = true,
  });

  factory Matchday.fromJson(Map<String, dynamic> json) {
    return Matchday(
      giornata: (json['giornata'] ?? 0) as int,
      deadline: (json['deadline'] as Timestamp?)?.toDate() ??
          DateTime.now().subtract(const Duration(days: 1)),
      availableTeams: List<String>.from(json['availableTeams'] ?? json['validTeams'] ?? []),
      status: MatchdayStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MatchdayStatus.upcoming,
      ),
      startDate: (json['startDate'] as Timestamp?)?.toDate(),
      endDate: (json['endDate'] as Timestamp?)?.toDate(),
      participantsCount: (json['participantsCount'] ?? 0) as int,
      activePlayers: (json['activePlayers'] ?? 0) as int,
      doubleChoiceAvailable: (json['doubleChoiceAvailable'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'giornata': giornata,
      'deadline': Timestamp.fromDate(deadline),
      'availableTeams': availableTeams,
      'status': status.name,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'participantsCount': participantsCount,
      'activePlayers': activePlayers,
      'doubleChoiceAvailable': doubleChoiceAvailable,
    };
  }

  /// Deadline: 23:59 del giorno prima della giornata
  bool get isOpen => DateTime.now().isBefore(deadline) && status == MatchdayStatus.active;
  bool get isExpired => DateTime.now().isAfter(deadline);
  bool get isFinalMatchday => giornata == 38;

  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(deadline)) return Duration.zero;
    return deadline.difference(now);
  }

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

  bool isTeamAvailable(String team) => availableTeams.contains(team);

  Matchday copyWith({
    int? giornata,
    DateTime? deadline,
    List<String>? availableTeams,
    MatchdayStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? participantsCount,
    int? activePlayers,
    bool? doubleChoiceAvailable,
  }) {
    return Matchday(
      giornata: giornata ?? this.giornata,
      deadline: deadline ?? this.deadline,
      availableTeams: availableTeams ?? this.availableTeams,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      participantsCount: participantsCount ?? this.participantsCount,
      activePlayers: activePlayers ?? this.activePlayers,
      doubleChoiceAvailable: doubleChoiceAvailable ?? this.doubleChoiceAvailable,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Matchday &&
        other.giornata == giornata &&
        other.deadline == deadline &&
        other.status == status &&
        listEquals(other.availableTeams, availableTeams);
  }

  @override
  int get hashCode => Object.hash(giornata, deadline, status);

  @override
  String toString() =>
      'Matchday(giornata: $giornata, status: ${status.name}, teams: ${availableTeams.length})';
}
