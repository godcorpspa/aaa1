class UserData {
  final int jollyLeft;
  final List<String> teamsUsed;

  UserData({
    required this.jollyLeft,
    required this.teamsUsed,
  });

  factory UserData.fromJson(Map<String, dynamic> j) => UserData(
      jollyLeft: (j['jollyLeft'] ?? 0) as int,
      teamsUsed: List<String>.from(j['teamsUsed'] ?? []),
    );
}
