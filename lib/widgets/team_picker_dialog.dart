import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TeamPickerDialog extends StatefulWidget {
  final List<String> allowedTeams;
  final List<String> blockedTeams;
  final String? currentSelection;

  const TeamPickerDialog({
    super.key,
    required this.allowedTeams,
    required this.blockedTeams,
    this.currentSelection,
  });

  @override
  State<TeamPickerDialog> createState() => _TeamPickerDialogState();
}

class _TeamPickerDialogState extends State<TeamPickerDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  List<String> _filteredTeams = [];
  String? _selectedTeam;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    
    _selectedTeam = widget.currentSelection;
    _updateFilteredTeams();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _updateFilteredTeams() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTeams = widget.allowedTeams
          .where((team) => team.toLowerCase().contains(query))
          .toList()
        ..sort();
    });
  }

  void _selectTeam(String team) {
    if (widget.blockedTeams.contains(team)) return;
    
    HapticFeedback.selectionClick();
    setState(() => _selectedTeam = team);
  }

  void _confirmSelection() {
    if (_selectedTeam != null) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(_selectedTeam);
    }
  }

  Widget _buildTeamLogo(String team) {
    // Placeholder per loghi delle squadre - sostituire con veri asset
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _getTeamColor(team),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          team.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Color _getTeamColor(String team) {
    // Colori rappresentativi per le squadre
    final colors = {
      'Inter': const Color(0xFF0066CC),
      'Milan': const Color(0xFFE60026),
      'Juventus': Colors.black,
      'Roma': const Color(0xFF8B0000),
      'Lazio': const Color(0xFF87CEEB),
      'Napoli': const Color(0xFF0066CC),
      'Atalanta': const Color(0xFF003366),
      'Fiorentina': const Color(0xFF800080),
    };
    
    return colors[team] ?? Colors.grey[600]!;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nessuna squadra trovata',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prova con un altro termine di ricerca',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE64A19),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.sports_soccer,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Scegli la tua squadra',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Cerca squadra...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _updateFilteredTeams();
                                },
                                icon: const Icon(Icons.clear, color: Colors.white),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) => _updateFilteredTeams(),
                    ),
                  ],
                ),
              ),
              
              // Teams List
              Expanded(
                child: _filteredTeams.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredTeams.length,
                        itemBuilder: (context, index) {
                          final team = _filteredTeams[index];
                          final isBlocked = widget.blockedTeams.contains(team);
                          final isSelected = team == _selectedTeam;
                          
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 200 + (index * 50)),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isBlocked ? null : () => _selectTeam(team),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFE64A19).withOpacity(0.1)
                                        : isBlocked
                                            ? Colors.grey[100]
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFE64A19)
                                          : isBlocked
                                              ? Colors.grey[300]!
                                              : Colors.grey[200]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFE64A19).withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                  ),
                                  child: Row(
                                    children: [
                                      _buildTeamLogo(team),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          team,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isBlocked
                                                ? Colors.grey[500]
                                                : isSelected
                                                    ? const Color(0xFFE64A19)
                                                    : Colors.black87,
                                            decoration: isBlocked
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFFE64A19),
                                          size: 24,
                                        ),
                                      if (isBlocked)
                                        Icon(
                                          Icons.block,
                                          color: Colors.grey[500],
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              
              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFE64A19)),
                        ),
                        child: const Text(
                          'Annulla',
                          style: TextStyle(
                            color: Color(0xFFE64A19),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedTeam != null ? _confirmSelection : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE64A19),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Conferma',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}