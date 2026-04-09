import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // === COLORI PRIMARI ===
  static const Color primaryRed = Color(0xFFE53935);
  static const Color primaryDark = Color(0xFF0D0D12);
  static const Color accentGold = Color(0xFFFFCA28);
  static const Color accentOrange = Color(0xFFFF7043);
  static const Color accentCyan = Color(0xFF26C6DA);

  // === COLORI SEMANTICI ===
  static const Color successGreen = Color(0xFF66BB6A);
  static const Color warningAmber = Color(0xFFFFCA28);
  static const Color errorRed = Color(0xFFEF5350);
  static const Color infoBlue = Color(0xFF42A5F5);

  // === SUPERFICI ===
  static const Color surfaceDark = Color(0xFF111118);
  static const Color surfaceCard = Color(0xFF1A1A24);
  static const Color surfaceElevated = Color(0xFF22222E);
  static const Color surfaceLight = Color(0xFFF5F5F5);

  // === GRADIENTI ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFC62828)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0D0D12), Color(0xFF111118), Color(0xFF16161F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E2A), Color(0xFF1A1A24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFFCA28), Color(0xFFFFA726)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF5350), Color(0xFFE53935)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF26C6DA), Color(0xFF0097A7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === TEMA PRINCIPALE ===
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      fontFamily: 'Roboto',

      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        onPrimary: Colors.white,
        secondary: accentGold,
        onSecondary: Colors.black,
        tertiary: accentCyan,
        error: errorRed,
        onError: Colors.white,
        surface: surfaceDark,
        onSurface: Colors.white,
        surfaceContainerHighest: surfaceElevated,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        prefixIconColor: Colors.white38,
        suffixIconColor: Colors.white38,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentCyan,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        color: surfaceCard,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        elevation: 24,
        backgroundColor: surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 15,
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: surfaceDark,
        elevation: 0,
        selectedItemColor: primaryRed,
        unselectedItemColor: Colors.white.withValues(alpha: 0.35),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),

      // Progress
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryRed,
        linearTrackColor: surfaceElevated,
        circularTrackColor: surfaceElevated,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.06),
        thickness: 1,
        space: 1,
      ),

      // ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        iconColor: Colors.white.withValues(alpha: 0.6),
        textColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: primaryRed,
        disabledColor: surfaceCard,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryRed;
          return Colors.white54;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryRed.withValues(alpha: 0.4);
          }
          return Colors.white.withValues(alpha: 0.08);
        }),
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        indicatorColor: primaryRed,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
    );
  }

  // === DECORAZIONI RIUTILIZZABILI ===

  static BoxDecoration get glassCard => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      );

  static BoxDecoration get elevatedCard => BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get goldCard => BoxDecoration(
        gradient: goldGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentGold.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration statusCard(StatusType status) {
    final color = _statusColor(status);
    return BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    );
  }

  static Color _statusColor(StatusType status) {
    switch (status) {
      case StatusType.success:
        return successGreen;
      case StatusType.warning:
        return warningAmber;
      case StatusType.error:
        return errorRed;
      case StatusType.info:
        return infoBlue;
    }
  }

  // === STILI PER PULSANTI DI STATO ===
  static ButtonStyle statusButton(StatusType status) {
    final color = _statusColor(status);
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// === ENUMS ===

enum StatusType { success, warning, error, info }

// === COSTANTI DI SPAZIATURA ===

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
}

class AppSizes {
  static const double buttonHeight = 54.0;
  static const double inputHeight = 56.0;
  static const double cardMinHeight = 100.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 72.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
}
