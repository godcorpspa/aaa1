import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TeamPickerDialog extends StatefulWidget {
  final List<String> availableTeams;
  final List<String> usedTeams;
  final String? initialSelection;
  final bool allowDoubleChoice;

  const TeamPickerDialog({
    super.key,
    required this.availableTeams,
    required this.usedTeams,
    this.initialSelection,
    this.allowDoubleChoice = false,
  });

  @override
  State<TeamPickerDialog> createState() => _TeamPickerDialogState();
}

class _TeamPickerDialogState extends State<TeamPickerDialog> {
  String _searchQuery = '';
  String? _selectedTeam;
  String? _secondTeam;
  bool _isDoubleChoice = false;

  @override
  void initState() {
    super.initState();
    _selectedTeam = widget.initialSelection;
  }

  List<String> get _filteredTeams {
    final teams = widget.availableTeams
        .where((t) => !widget.usedTeams.contains(t))
        .toList();
    if (_searchQuery.isEmpty) return teams;
    return teams
        .where((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 520, maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Scegli Squadra',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cerca squadra...',
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            if (widget.allowDoubleChoice) ...[
              const SizedBox(height: 12),
              _buildDoubleChoiceToggle(),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: _filteredTeams.isEmpty
                  ? Center(
                      child: Text(
                        'Nessuna squadra disponibile',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredTeams.length,
                      itemBuilder: (_, i) =>
                          _buildTeamTile(_filteredTeams[i]),
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTeam != null &&
                        (!_isDoubleChoice || _secondTeam != null)
                    ? () => Navigator.pop(context, {
                          'team': _selectedTeam,
                          'secondTeam': _isDoubleChoice ? _secondTeam : null,
                          'isDoubleChoice': _isDoubleChoice,
                        })
                    : null,
                child: Text(_isDoubleChoice
                    ? 'Conferma Doppia Scelta'
                    : 'Conferma Scelta'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoubleChoiceToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _isDoubleChoice
            ? AppTheme.accentGold.withValues(alpha: 0.15)
            : AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDoubleChoice
              ? AppTheme.accentGold.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: const Text(
          'Doppia Scelta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Scegli 2 squadre: entrambe devono vincere per ottenere un Gold Ticket',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
        value: _isDoubleChoice,
        onChanged: (v) => setState(() {
          _isDoubleChoice = v;
          if (!v) _secondTeam = null;
        }),
      ),
    );
  }

  Widget _buildTeamTile(String team) {
    final isFirst = team == _selectedTeam;
    final isSecond = team == _secondTeam;
    final isSelected = isFirst || isSecond;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected
            ? AppTheme.primaryRed.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              if (_isDoubleChoice) {
                if (isFirst) {
                  _selectedTeam = null;
                } else if (isSecond) {
                  _secondTeam = null;
                } else if (_selectedTeam == null) {
                  _selectedTeam = team;
                } else if (_secondTeam == null) {
                  _secondTeam = team;
                } else {
                  _selectedTeam = team;
                  _secondTeam = null;
                }
              } else {
                _selectedTeam = isFirst ? null : team;
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isSelected
                      ? AppTheme.primaryRed
                      : AppTheme.surfaceElevated,
                  child: Text(
                    team.isNotEmpty ? team[0] : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    team,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                if (isFirst)
                  _badge(
                    _isDoubleChoice ? '1' : 'OK',
                    AppTheme.primaryRed,
                    Colors.white,
                  ),
                if (isSecond)
                  _badge('2', AppTheme.accentGold, Colors.black),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
