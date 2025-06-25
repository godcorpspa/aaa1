class Pick {
  final int giornata;
  final String team;
  final bool usedJolly;

  Pick({
    required this.giornata,
    required this.team,
    this.usedJolly = false,
  });

  Map<String, dynamic> toJson() => {
        'giornata': giornata,
        'team': team,
        'usedJolly': usedJolly,
      };
}
