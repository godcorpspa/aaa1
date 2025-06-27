import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // === COLORI ===
  static const Color primaryRed = Color(0xFFB71C1C);
  static const Color primaryOrange = Color(0xFFBF360C);
  static const Color accentOrange = Color(0xFFE64A19);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningYellow = Color(0xFFFFC107);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);
  
  // Gradienti
  static const LinearGradient gradient = LinearGradient(
    colors: [primaryRed, primaryOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient lightGradient = LinearGradient(
    colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFB74D), Color(0xFFFFC107)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === TIPOGRAFIA ===
  static const String fontFamily = 'SF Pro Display';
  
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.25,
      height: 1.2,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      height: 1.2,
    ),
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.5,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.25,
      height: 1.4,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.25,
      height: 1.4,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.5,
      height: 1.4,
    ),
  );

  // === TEMA PRINCIPALE ===
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentOrange,
        brightness: Brightness.light,
        primary: accentOrange,
        secondary: primaryOrange,
        error: errorRed,
        surface: Colors.white,
        onSurface: Colors.black87,
      ),
      
      // Tipografia
      textTheme: textTheme,
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: Colors.white70),
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white38, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        ),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.25,
          ),
        ),
      ),
      
      // Card
      cardTheme: const CardThemeData(
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineSmall!.copyWith(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: textTheme.bodyMedium!.copyWith(
          color: Colors.black87,
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.black87,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentOrange,
        linearTrackColor: Colors.white24,
        circularTrackColor: Colors.white24,
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentOrange;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentOrange.withOpacity(0.5);
          }
          return Colors.white30;
        }),
      ),
      
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentOrange;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: Colors.white70, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.3),
        thickness: 1,
        space: 1,
      ),
      
      // List Tile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: Colors.white70,
        textColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
    );
  }

  // === TEMA SCURO ===
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.dark,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentOrange,
        brightness: Brightness.dark,
        primary: accentOrange,
        secondary: primaryOrange,
        error: errorRed,
        surface: const Color(0xFF121212),
        onSurface: Colors.white,
      ),
      
      textTheme: textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      
      scaffoldBackgroundColor: const Color(0xFF121212),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: Color(0xFF1E1E1E),
      ),
      
      // Altri componenti per tema scuro...
    );
  }

  // === STILI PERSONALIZZATI ===
  
  /// Stile per pulsanti di stato (successo, warning, errore)
  static ButtonStyle getStatusButtonStyle(StatusType status) {
    Color backgroundColor;
    Color foregroundColor = Colors.white;
    
    switch (status) {
      case StatusType.success:
        backgroundColor = successGreen;
        break;
      case StatusType.warning:
        backgroundColor = warningYellow;
        foregroundColor = Colors.black87;
        break;
      case StatusType.error:
        backgroundColor = errorRed;
        break;
      case StatusType.info:
        backgroundColor = infoBlue;
        break;
    }
    
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
  
  /// Decorazione per container con gradiente
  static BoxDecoration getGradientDecoration({
    LinearGradient? gradient,
    double borderRadius = 12,
    Color? borderColor,
    double borderWidth = 0,
  }) {
    return BoxDecoration(
      gradient: gradient ?? AppTheme.gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: borderColor != null 
        ? Border.all(color: borderColor, width: borderWidth)
        : null,
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
  
  /// Stile per text field personalizzati
  static InputDecoration getCustomInputDecoration({
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    Color backgroundColor = Colors.transparent,
    Color borderColor = Colors.white38,
    Color focusedBorderColor = Colors.white,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null 
        ? Icon(prefixIcon, color: Colors.white70) 
        : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: backgroundColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: focusedBorderColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
  
  /// Shadow per elevation personalizzata
  static List<BoxShadow> getElevationShadow(double elevation) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: elevation * 2,
        offset: Offset(0, elevation),
      ),
    ];
  }
  
  /// Animazione di transizione personalizzata
  static Widget slideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: child,
    );
  }
}

// === ENUMS E HELPER ===

enum StatusType { success, warning, error, info }

/// Estensione per colori con opacità
extension ColorExtension on Color {
  Color get light => withOpacity(0.7);
  Color get lighter => withOpacity(0.5);
  Color get lightest => withOpacity(0.3);
  Color get dark => Color.fromRGBO(
    (red * 0.8).round(),
    (green * 0.8).round(), 
    (blue * 0.8).round(),
    1.0,
  );
}

/// Costanti per spacing
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Costanti per border radius
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double circle = 50.0;
}

/// Costanti per dimensioni
class AppSizes {
  static const double buttonHeight = 56.0;
  static const double inputHeight = 56.0;
  static const double cardMinHeight = 120.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 80.0;
}