import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// Widget riutilizzabile per mostrare il logo di una squadra
/// Supporta cache delle immagini e fallback con iniziale
class TeamLogo extends StatelessWidget {
  final String teamName;
  final String? logoUrl;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const TeamLogo({
    super.key,
    required this.teamName,
    this.logoUrl,
    this.size = 40,
    this.backgroundColor,
    this.textColor,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidUrl = logoUrl != null && logoUrl!.isNotEmpty;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hasValidUrl ? Colors.white : (backgroundColor ?? AppTheme.accentOrange),
        borderRadius: BorderRadius.circular(size / 2),
        border: showBorder
            ? Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.3),
                width: borderWidth,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: hasValidUrl
            ? CachedNetworkImage(
                imageUrl: logoUrl!,
                width: size,
                height: size,
                fit: BoxFit.contain,
                placeholder: (context, url) => _buildPlaceholder(),
                errorWidget: (context, url, error) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentOrange),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: backgroundColor ?? AppTheme.accentOrange,
      child: Center(
        child: Text(
          _getInitials(),
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    if (teamName.isEmpty) return '?';
    
    // Gestione nomi speciali
    final specialNames = {
      'AC Milan': 'ACM',
      'Inter': 'INT',
      'Juventus': 'JUV',
      'Napoli': 'NAP',
      'Roma': 'ROM',
      'Lazio': 'LAZ',
      'Atalanta': 'ATA',
      'Fiorentina': 'FIO',
      'Bologna': 'BOL',
      'Torino': 'TOR',
      'Udinese': 'UDI',
      'Sassuolo': 'SAS',
      'Empoli': 'EMP',
      'Verona': 'VER',
      'Lecce': 'LEC',
      'Monza': 'MON',
      'Cagliari': 'CAG',
      'Genoa': 'GEN',
      'Frosinone': 'FRO',
      'Salernitana': 'SAL',
      'Parma': 'PAR',
      'Como': 'COM',
      'Venezia': 'VEN',
    };

    // Cerca nome esatto o parziale
    for (final entry in specialNames.entries) {
      if (teamName.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Fallback: prime lettere delle parole
    final words = teamName.split(' ');
    if (words.length >= 2) {
      return words.take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    }
    
    return teamName.substring(0, teamName.length >= 3 ? 3 : teamName.length).toUpperCase();
  }
}

/// Widget per mostrare il logo con il nome della squadra
class TeamLogoWithName extends StatelessWidget {
  final String teamName;
  final String? logoUrl;
  final double logoSize;
  final double spacing;
  final TextStyle? textStyle;
  final bool nameFirst;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const TeamLogoWithName({
    super.key,
    required this.teamName,
    this.logoUrl,
    this.logoSize = 32,
    this.spacing = 8,
    this.textStyle,
    this.nameFirst = false,
    this.direction = Axis.horizontal,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final logo = TeamLogo(
      teamName: teamName,
      logoUrl: logoUrl,
      size: logoSize,
    );

    final name = Flexible(
      child: Text(
        teamName,
        style: textStyle ?? const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );

    final children = nameFirst
        ? [name, SizedBox(width: spacing, height: spacing), logo]
        : [logo, SizedBox(width: spacing, height: spacing), name];

    if (direction == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

/// Widget per confronto tra due squadre (es. partite)
class TeamVsTeam extends StatelessWidget {
  final String homeTeamName;
  final String? homeTeamLogo;
  final String awayTeamName;
  final String? awayTeamLogo;
  final double logoSize;
  final Widget? centerWidget;
  final TextStyle? teamNameStyle;
  final bool showTeamNames;

  const TeamVsTeam({
    super.key,
    required this.homeTeamName,
    this.homeTeamLogo,
    required this.awayTeamName,
    this.awayTeamLogo,
    this.logoSize = 40,
    this.centerWidget,
    this.teamNameStyle,
    this.showTeamNames = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Squadra casa
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TeamLogo(
                teamName: homeTeamName,
                logoUrl: homeTeamLogo,
                size: logoSize,
              ),
              if (showTeamNames) ...[
                const SizedBox(height: 8),
                Text(
                  homeTeamName,
                  style: teamNameStyle ?? const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        
        // Centro (VS o risultato)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: centerWidget ?? const Text(
            'VS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Squadra trasferta
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TeamLogo(
                teamName: awayTeamName,
                logoUrl: awayTeamLogo,
                size: logoSize,
              ),
              if (showTeamNames) ...[
                const SizedBox(height: 8),
                Text(
                  awayTeamName,
                  style: teamNameStyle ?? const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}