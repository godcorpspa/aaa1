import 'package:flutter/material.dart';

class TeamPickerDialog extends StatelessWidget {
  final List<String> allowedTeams;
  final List<String> blockedTeams;
  const TeamPickerDialog({
    super.key,
    required this.allowedTeams,
    required this.blockedTeams,
  });

  @override
  Widget build(BuildContext context) {
    final teams = [...allowedTeams]..sort();
    return AlertDialog(
      title: const Text('Seleziona la squadra'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          itemCount: teams.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final team = teams[i];
            final disabled = blockedTeams.contains(team);
            return ListTile(
              title: Text(
                team,
                style: disabled
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null,
              ),
              enabled: !disabled,
              onTap: disabled ? null : () => Navigator.pop(context, team),
            );
          },
        ),
      ),
    );
  }
}