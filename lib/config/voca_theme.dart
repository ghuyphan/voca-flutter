// lib/config/voca_theme.dart

import 'package:flutter/material.dart';

/// Authentic VOCA Design System tokens extracted directly from
/// lingua-tube's src/styles/_variables.scss
class VocaTokens {
  // Rich Obsidian Palette (Dark Mode - Apple & Linear Inspired)
  static const Color bgPrimary = Color(0xFF0D0F14);
  static const Color bgSecondary = Color(0xFF13161F);
  static const Color bgTertiary = Color(0xFF191D28);
  static const Color bgCard = Color(0xFF181B24);
  static const Color bgSurface = Color(0xFF1E222D);
  static const Color bgHover = Color(0xFF252A37);

  // Border tokens
  static const Color borderColor = Color(0xFF272D3B);
  static const Color borderColorLight = Color(0xFF1F2430);
  static const Color borderColorHover = Color(0xFF394256);

  // Typography tokens
  static const Color textPrimary = Color(0xFFF1F3F7);
  static const Color textSecondary = Color(0xFF969EB2);
  static const Color textMuted = Color(0xFF7D879F);
  static const Color textTertiary = Color(0xFF545C70);
  static const Color textInverse = Color(0xFF0D0F14);

  // Radiant Coral Accent (Signature VOCA color)
  static const Color accentPrimary = Color(0xFFFF6B82);
  static const Color accentPrimaryHover = Color(0xFFFF8095);
  static const Color accentPrimaryShadow = Color(0xFFE03E58);
  static const Color accentPrimarySoft = Color(0x1FFF6B82);

  // Secondary & Tertiary Accents
  static const Color accentSecondary = Color(0xFFA78BFA); // Purple
  static const Color accentSecondarySoft = Color(0x1FA78BFA);
  static const Color accentTertiary = Color(0xFFFBBF24); // Gold / Amber

  // Gamification & Semantics
  static const Color colorFire = Color(0xFFEA580C); // Streak flame
  static const Color colorDiamond = Color(0xFF0284C7); // AI Credit / Diamond
  static const Color colorGrammar = Color(0xFF10B981); // Crisp mint / emerald
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Word Mastery Status Colors
  static const Color wordNewBg = Color(0x26FF6B82);
  static const Color wordNewText = Color(0xFFFF8CA0);
  static const Color wordLearningBg = Color(0x26FBBF24);
  static const Color wordLearningText = Color(0xFFFCD34D);
  static const Color wordKnownBg = Color(0x2638BDF8);
  static const Color wordKnownText = Color(0xFF7DD3FC);
  static const Color wordMasteredBg = Color(0x264ADE80);
  static const Color wordMasteredText = Color(0xFF86EFAC);

  // Chill Pastel Grammar / Difficulty Level Colors (Dark Mode)
  static const Color levelBeginnerBg = Color(0x2458AFFF);
  static const Color levelBeginnerText = Color(0xFF9BCEFF);
  static const Color levelBeginnerBorder = Color(0x4058AFFF);

  static const Color levelElementaryBg = Color(0x2438D9EE);
  static const Color levelElementaryText = Color(0xFF67E8F9);
  static const Color levelElementaryBorder = Color(0x4038D9EE);

  static const Color levelIntermediateBg = Color(0x24FBC53D);
  static const Color levelIntermediateText = Color(0xFFFDE068);
  static const Color levelIntermediateBorder = Color(0x40FBC53D);

  static const Color levelUpperBg = Color(0x24FB923C);
  static const Color levelUpperText = Color(0xFFFDBA74);
  static const Color levelUpperBorder = Color(0x40FB923C);

  static const Color levelAdvancedBg = Color(0x24FF7891);
  static const Color levelAdvancedText = Color(0xFFFFA4B5);
  static const Color levelAdvancedBorder = Color(0x40FF7891);

  // Responsive Breakpoints
  static const double tabletBreakpoint = 720.0;
  static const double desktopBreakpoint = 1024.0;
}

class VocaTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VocaTokens.bgPrimary,
      canvasColor: VocaTokens.bgPrimary,
      cardColor: VocaTokens.bgCard,
      dividerColor: VocaTokens.borderColor,
      colorScheme: const ColorScheme.dark(
        primary: VocaTokens.accentPrimary,
        onPrimary: Colors.white,
        secondary: VocaTokens.accentSecondary,
        onSecondary: Colors.white,
        surface: VocaTokens.bgCard,
        onSurface: VocaTokens.textPrimary,
        error: VocaTokens.error,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: VocaTokens.bgPrimary,
        foregroundColor: VocaTokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: VocaTokens.bgSecondary,
        selectedItemColor: VocaTokens.accentPrimary,
        unselectedItemColor: VocaTokens.textMuted,
      ),
      cardTheme: CardThemeData(
        color: VocaTokens.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: VocaTokens.borderColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VocaTokens.accentPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VocaTokens.textPrimary,
          side: const BorderSide(color: VocaTokens.borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: VocaTokens.textPrimary),
        bodyMedium: TextStyle(color: VocaTokens.textPrimary),
        bodySmall: TextStyle(color: VocaTokens.textSecondary),
        titleLarge: TextStyle(color: VocaTokens.textPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: VocaTokens.textPrimary, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: VocaTokens.textSecondary, fontWeight: FontWeight.w500),
      ),
    );
  }
}
