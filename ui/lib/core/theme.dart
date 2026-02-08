import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeType {
  forestCalm,
  nightFocus,
  sunriseStudy,
  oceanSilence,
  minimalDark,
  heaven,
  deepFocus,
}

class AppTheme {
  // --- Theme Configurations ---
  
  static final Map<AppThemeType, ThemeConfig> _themes = {
    AppThemeType.forestCalm: ThemeConfig(
      name: 'Forest Calm',
      primary: const Color(0xFFA3E635),     // Lime Green
      secondary: const Color(0xFF10B981),   // Emerald
      background: const Color(0xFF022C22),  // Deepest Emerald
      surface: const Color(0xFF064E3B),     // Dark Green
      card: const Color(0xFF065F46),        // Muted Green Card
      textPrimary: const Color(0xFFECFDF5), // Off White Mint
      textSecondary: const Color(0xFF34D399),// Light Emerald
      navBarColor: const Color(0xFF022C22),
      isDark: true,
    ),
    AppThemeType.nightFocus: ThemeConfig(
      name: 'Night Focus',
      primary: const Color(0xFF22D3EE),     // Cyan 400
      secondary: const Color(0xFF818CF8),   // Indigo 400
      background: const Color(0xFF0F172A),  // Slate 900
      surface: const Color(0xFF1E293B),     // Slate 800
      card: const Color(0xFF334155),        // Slate 700
      textPrimary: const Color(0xFFF8FAFC), // Slate 50
      textSecondary: const Color(0xFF94A3B8),// Slate 400
      navBarColor: const Color(0xFF0F172A),
      isDark: true,
    ),
    AppThemeType.sunriseStudy: ThemeConfig(
      name: 'Sunrise Focus',
      primary: const Color(0xFFFBBF24),     // Amber 400
      secondary: const Color(0xFFF87171),   // Red/Salmon 400
      background: const Color(0xFF451A03),  // Warm Brown
      surface: const Color(0xFF78350F),     // Burnt Orange
      card: const Color(0xFF92400E),        // Warm Amber
      textPrimary: const Color(0xFFFFF7ED), // Off White Orange
      textSecondary: const Color(0xFFFDE68A),// Light Amber
      navBarColor: const Color(0xFF451A03),
      isDark: true,
    ),
    AppThemeType.oceanSilence: ThemeConfig(
      name: 'Ocean Silence',
      primary: const Color(0xFF38BDF8),     // Sky 400
      secondary: const Color(0xFF1D4ED8),   // Blue 700
      background: const Color(0xFF082F49),  // Deep Oceanic Blue
      surface: const Color(0xFF0C4A6E),     // Dark Blue
      card: const Color(0xFF075985),        // Muted Blue
      textPrimary: const Color(0xFFF0F9FF), // Ice White
      textSecondary: const Color(0xFFBAE6FD),// Light Sky
      navBarColor: const Color(0xFF082F49),
      isDark: true,
    ),
    AppThemeType.minimalDark: ThemeConfig(
      name: 'Minimal Dark',
      primary: const Color(0xFFF8FAFC),     // Slate 50
      secondary: const Color(0xFF64748B),   // Slate 500
      background: const Color(0xFF020617),  // Deepest Blue-Black
      surface: const Color(0xFF0F172A),     // Navy Slate
      card: const Color(0xFF1E293B),        // Dark Slate
      textPrimary: const Color(0xFFFFFFFF),
      textSecondary: const Color(0xFF94A3B8),// Slate 400
      navBarColor: const Color(0xFF020617),
      isDark: true,
    ),
    AppThemeType.heaven: ThemeConfig(
      name: 'Heaven',
      primary: const Color(0xFF0EA5E9),     // Ocean Blue
      secondary: const Color(0xFF6366F1),   // Indigo
      background: const Color(0xFFF8FAFC),  // Light Gray
      surface: const Color(0xFFFFFFFF),     // White
      card: const Color(0xFFF1F5F9),        // Soft Gray Card
      textPrimary: const Color(0xFF0F172A), // Deep Slate
      textSecondary: const Color(0xFF64748B),// Slate Gray
      navBarColor: const Color(0xFFFFFFFF),
      isDark: false,
    ),
    AppThemeType.deepFocus: ThemeConfig(
      name: 'Deep Focus',
      primary: const Color(0xFF8B5CF6),     // Violet 500
      secondary: const Color(0xFFD946EF),   // Fuchsia 500
      background: const Color(0xFF2E1065),  // Deepest Purple
      surface: const Color(0xFF4C1D95),     // Dark Purple
      card: const Color(0xFF5B21B6),        // Muted Purple
      textPrimary: const Color(0xFFF5F3FF), // Light Lavender
      textSecondary: const Color(0xFFC4B5FD),// Soft Violet
      navBarColor: const Color(0xFF2E1065),
      isDark: true,
    ),
  };

  static ThemeData getTheme(AppThemeType type) {
    final config = _themes[type]!;
    
    return ThemeData(
      useMaterial3: true,
      brightness: config.isDark ? Brightness.dark : Brightness.light,
      primaryColor: config.primary,
      scaffoldBackgroundColor: config.background,
      cardColor: config.card,
      
      colorScheme: ColorScheme(
        brightness: config.isDark ? Brightness.dark : Brightness.light,
        primary: config.primary,
        onPrimary: config.isDark ? Colors.black : Colors.white,
        secondary: config.secondary,
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: config.surface,
        onSurface: config.textPrimary,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: config.textPrimary,
        ),
        iconTheme: IconThemeData(color: config.textPrimary),
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: config.textPrimary,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: config.textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: config.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: config.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: config.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: config.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: config.textSecondary,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.primary,
          foregroundColor: config.isDark ? Colors.black : Colors.white,
          elevation: 8,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: config.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: config.card),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: config.card),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: config.primary, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: config.textSecondary),
        hintStyle: GoogleFonts.inter(color: config.textSecondary.withValues(alpha: 0.7)),
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: config.navBarColor,
        selectedItemColor: config.primary,
        unselectedItemColor: config.textSecondary,
      ),
    );
  }
  
  // Helper to get raw config if needed
  static ThemeConfig getConfig(AppThemeType type) => _themes[type]!;

  // Default theme
  static ThemeData get lightTheme => getTheme(AppThemeType.forestCalm);
  static ThemeData get darkTheme => getTheme(AppThemeType.nightFocus);

  // Common Gradients & Effects based on current config
  static LinearGradient getPrimaryGradient(AppThemeType type) {
    final config = _themes[type]!;
    return LinearGradient(
      colors: [config.primary, config.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  // --- Static Palette (Legacy/Brand) ---
  static const Color darkBackground = Color(0xFF0A0E27);
  static const Color darkSurface = Color(0xFF151A30);
  static const Color darkCard = Color(0xFF1E2538);
  
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonPurple = Color(0xFF9D4EDD);
  static const Color neonBlue = Color(0xFF5B7CFF);
  static const Color neonGreen = Color(0xFF3FE0A0);
  static const Color neonRed = Color(0xFFFF4D6D);
  static const Color textSecondary = Color(0xFFB0B8D4); // Fallback
  
  // Backward compatibility - static gradient getters
  static LinearGradient get primaryGradient => getPrimaryGradient(AppThemeType.nightFocus);
  static LinearGradient get accentGradient => LinearGradient(
    colors: [neonPurple, neonBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Additional legacy getters for old screens
  static Color get textPrimary => Colors.white;
  static Color get textTertiary => Colors.white54;
  static Color get glassBackgroundColor => darkCard.withValues(alpha: 0.3);
  static Color get glassBorderColor => Colors.white.withValues(alpha: 0.1);

  static List<BoxShadow> createGlow(Color color, {double blur = 20, double spread = 5}) {
     return [
      BoxShadow(
        color: color.withValues(alpha: 0.4),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  // Helper to access common getters if used statically
  // Note: It's better to use Theme.of(context)
  
  static List<BoxShadow> get cyanGlow => createGlow(neonCyan);
}

class ThemeConfig {
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color navBarColor;
  final bool isDark;

  const ThemeConfig({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.navBarColor,
    required this.isDark,
  });
}
