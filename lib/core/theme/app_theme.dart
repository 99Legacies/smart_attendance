import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// AttendPro design system — premium B2B SaaS aesthetic (dark-first).
class AppTheme {
  AppTheme._();

  // ── Dark palette ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0F1E);
  static const Color surface = Color(0xFF131929);
  static const Color surfaceVariant = Color(0xFF1E2640);
  static const Color primary = Color(0xFF5B6BF8);
  static const Color primaryContainer = Color(0xFF1E2456);
  static const Color secondary = Color(0xFF10B981);
  static const Color error = Color(0xFFF43F5E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color onBackground = Color(0xFFF1F5F9);
  static const Color onSurface = Color(0xFFCBD5E1);
  static const Color outline = Color(0xFF2D3748);

  // ── Light palette ─────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEEF2FF);
  static const Color lightOnBackground = Color(0xFF0F172A);
  static const Color lightOnSurface = Color(0xFF334155);
  static const Color lightOutline = Color(0xFFE2E8F0);

  // ── Semantic status ───────────────────────────────────────────────────────
  static const Color present = Color(0xFF10B981);
  static const Color late = Color(0xFFF59E0B);
  static const Color absent = Color(0xFFF43F5E);

  // ── Gradients & decoration ─────────────────────────────────────────────────
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B6BF8), Color(0xFF7C3AED)],
  );
  static const Gradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF22C55E)],
  );
  static const Gradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );
  static const Gradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
  );
  static const Gradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0F1E), Color(0xFF131929)],
  );

  static const double borderRadius = 16.0;
  static const double borderRadiusLg = 24.0;
  static const double spacingUnit = 8.0;
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );

  static Color glassFill(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.72);

  static Color glassBorder(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

  static BoxDecoration gradientBackground(bool isDark) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [Color(0xFF060B1B), Color(0xFF0F1633), Color(0xFF120F2C)]
            : [Color(0xFFEFF2FF), Color(0xFFF7F9FE)],
      ),
    );
  }

  static TextTheme _headingTextTheme(Color color) {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  static TextTheme _bodyTextTheme(Color color) {
    return GoogleFonts.interTextTheme(
      TextTheme(
        bodyLarge: TextStyle(fontSize: 16, color: color, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, color: color, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, color: color, height: 1.4),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  static TextTheme textTheme(bool isDark) {
    final color = isDark ? onBackground : lightOnBackground;
    return _headingTextTheme(color).merge(_bodyTextTheme(color));
  }

  static SystemUiOverlayStyle systemOverlay(bool isDark) {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDark ? background : lightBackground,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
    );
  }

  static AppBarTheme appBarTheme(bool isDark) {
    final fg = isDark ? onBackground : lightOnBackground;
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: fg,
      iconTheme: IconThemeData(color: fg),
      actionsIconTheme: IconThemeData(color: fg),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
      systemOverlayStyle: systemOverlay(isDark),
    );
  }

  static ColorScheme _darkScheme() {
    return const ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onBackground,
      secondary: secondary,
      onSecondary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceVariant,
      outline: outline,
      outlineVariant: Color(0xFF1A2235),
    );
  }

  static ColorScheme _lightScheme() {
    return const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE0E7FF),
      onPrimaryContainer: Color(0xFF1E2456),
      secondary: secondary,
      onSecondary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: lightSurface,
      onSurface: lightOnSurface,
      surfaceContainerHighest: lightSurfaceVariant,
      outline: lightOutline,
      outlineVariant: Color(0xFFF1F5F9),
    );
  }

  static ThemeData dark() => _buildTheme(isDark: true);

  static ThemeData light() => _buildTheme(isDark: false);

  static ThemeData _buildTheme({required bool isDark}) {
    final scheme = isDark ? _darkScheme() : _lightScheme();
    final bg = isDark ? background : lightBackground;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme(isDark),
      appBarTheme: appBarTheme(isDark),
      cardTheme: CardThemeData(
        color: isDark ? surface : lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? surfaceVariant.withOpacity(0.6)
            : lightSurfaceVariant,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        labelStyle: GoogleFonts.inter(
          color: isDark ? onSurface : lightOnSurface,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: GoogleFonts.inter(
          color: (isDark ? onSurface : lightOnSurface).withOpacity(0.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: isDark ? outline : lightOutline,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: isDark ? outline : lightOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        prefixIconColor: isDark ? onSurface : lightOnSurface,
        suffixIconColor: isDark ? onSurface : lightOnSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(48, 48),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? surfaceVariant : lightOnBackground,
        contentTextStyle: GoogleFonts.inter(color: onBackground),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? outline : lightOutline,
        thickness: 1,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? surface : lightSurface,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? surfaceVariant : lightSurfaceVariant,
        labelStyle: GoogleFonts.inter(fontSize: 12),
        side: BorderSide(color: isDark ? outline : lightOutline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
