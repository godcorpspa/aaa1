import 'package:cloud_firestore/cloud_firestore.dart';

class Matchday {
  final int giornata;              // 1–38
  final DateTime deadline;         // scadenza scelta
  final List<String> validTeams;   // squadre consentite (giornate a tema)

  Matchday({
    required this.giornata,
    required this.deadline,
    required this.validTeams,
  });

  factory Matchday.fromJson(Map<String, dynamic> j) => Matchday(
      giornata: (j['giornata'] ?? 0) as int,
      deadline: (j['deadline'] as Timestamp?)?.toDate() ??
          DateTime.now().subtract(const Duration(days: 1)), // fallback passato
      validTeams: List<String>.from(j['validTeams'] ?? []),
    );
}
