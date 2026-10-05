// lib/config/voca_theme.dart

import 'package:flutter/material.dart';
export 'voca_tokens.dart';

/// Authentic VOCA Design System static tokens (Dark Mode default)
/// Preserved for backwards compatibility with existing direct usages.
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

/// Dynamic, theme-aware Color Palette containing tokens for both Light and Dark mode.
class VocaColorPalette {
  final bool isDark;

  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;
  final Color bgCard;
  final Color bgSurface;
  final Color bgHover;

  final Color borderColor;
  final Color borderColorLight;
  final Color borderColorHover;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textTertiary;
  final Color textInverse;

  final Color accentPrimary;
  final Color accentPrimaryHover;
  final Color accentPrimaryShadow;
  final Color accentPrimarySoft;

  final Color accentSecondary;
  final Color accentSecondarySoft;
  final Color accentTertiary;

  final Color colorFire;
  final Color colorDiamond;
  final Color colorGrammar;
  final Color success;
  final Color warning;
  final Color error;

  final Color wordNewBg;
  final Color wordNewText;
  final Color wordLearningBg;
  final Color wordLearningText;
  final Color wordKnownBg;
  final Color wordKnownText;
  final Color wordMasteredBg;
  final Color wordMasteredText;

  final Color levelBeginnerBg;
  final Color levelBeginnerText;
  final Color levelBeginnerBorder;

  final Color levelElementaryBg;
  final Color levelElementaryText;
  final Color levelElementaryBorder;

  final Color levelIntermediateBg;
  final Color levelIntermediateText;
  final Color levelIntermediateBorder;

  final Color levelUpperBg;
  final Color levelUpperText;
  final Color levelUpperBorder;

  final Color levelAdvancedBg;
  final Color levelAdvancedText;
  final Color levelAdvancedBorder;

  const VocaColorPalette({
    required this.isDark,
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.bgCard,
    required this.bgSurface,
    required this.bgHover,
    required this.borderColor,
    required this.borderColorLight,
    required this.borderColorHover,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textTertiary,
    required this.textInverse,
    required this.accentPrimary,
    required this.accentPrimaryHover,
    required this.accentPrimaryShadow,
    required this.accentPrimarySoft,
    required this.accentSecondary,
    required this.accentSecondarySoft,
    required this.accentTertiary,
    required this.colorFire,
    required this.colorDiamond,
    required this.colorGrammar,
    required this.success,
    required this.warning,
    required this.error,
    required this.wordNewBg,
    required this.wordNewText,
    required this.wordLearningBg,
    required this.wordLearningText,
    required this.wordKnownBg,
    required this.wordKnownText,
    required this.wordMasteredBg,
    required this.wordMasteredText,
    required this.levelBeginnerBg,
    required this.levelBeginnerText,
    required this.levelBeginnerBorder,
    required this.levelElementaryBg,
    required this.levelElementaryText,
    required this.levelElementaryBorder,
    required this.levelIntermediateBg,
    required this.levelIntermediateText,
    required this.levelIntermediateBorder,
    required this.levelUpperBg,
    required this.levelUpperText,
    required this.levelUpperBorder,
    required this.levelAdvancedBg,
    required this.levelAdvancedText,
    required this.levelAdvancedBorder,
  });

  /// Dark Mode Palette (Rich Obsidian)
  static const VocaColorPalette dark = VocaColorPalette(
    isDark: true,
    bgPrimary: Color(0xFF0D0F14),
    bgSecondary: Color(0xFF13161F),
    bgTertiary: Color(0xFF191D28),
    bgCard: Color(0xFF181B24),
    bgSurface: Color(0xFF1E222D),
    bgHover: Color(0xFF252A37),
    borderColor: Color(0xFF272D3B),
    borderColorLight: Color(0xFF1F2430),
    borderColorHover: Color(0xFF394256),
    textPrimary: Color(0xFFF1F3F7),
    textSecondary: Color(0xFF969EB2),
    textMuted: Color(0xFF7D879F),
    textTertiary: Color(0xFF545C70),
    textInverse: Color(0xFF0D0F14),
    accentPrimary: Color(0xFFFF6B82),
    accentPrimaryHover: Color(0xFFFF8095),
    accentPrimaryShadow: Color(0xFFE03E58),
    accentPrimarySoft: Color(0x1FFF6B82),
    accentSecondary: Color(0xFFA78BFA),
    accentSecondarySoft: Color(0x1FA78BFA),
    accentTertiary: Color(0xFFFBBF24),
    colorFire: Color(0xFFEA580C),
    colorDiamond: Color(0xFF0284C7),
    colorGrammar: Color(0xFF10B981),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    wordNewBg: Color(0x26FF6B82),
    wordNewText: Color(0xFFFF8CA0),
    wordLearningBg: Color(0x26FBBF24),
    wordLearningText: Color(0xFFFCD34D),
    wordKnownBg: Color(0x2638BDF8),
    wordKnownText: Color(0xFF7DD3FC),
    wordMasteredBg: Color(0x264ADE80),
    wordMasteredText: Color(0xFF86EFAC),
    levelBeginnerBg: Color(0x2458AFFF),
    levelBeginnerText: Color(0xFF9BCEFF),
    levelBeginnerBorder: Color(0x4058AFFF),
    levelElementaryBg: Color(0x2438D9EE),
    levelElementaryText: Color(0xFF67E8F9),
    levelElementaryBorder: Color(0x4038D9EE),
    levelIntermediateBg: Color(0x24FBC53D),
    levelIntermediateText: Color(0xFFFDE068),
    levelIntermediateBorder: Color(0x40FBC53D),
    levelUpperBg: Color(0x24FB923C),
    levelUpperText: Color(0xFFFDBA74),
    levelUpperBorder: Color(0x40FB923C),
    levelAdvancedBg: Color(0x24FF7891),
    levelAdvancedText: Color(0xFFFFA4B5),
    levelAdvancedBorder: Color(0x40FF7891),
  );

  /// Light Mode Palette (Crisp Porcelain - Apple & Linear Inspired)
  static const VocaColorPalette light = VocaColorPalette(
    isDark: false,
    bgPrimary: Color(0xFFF3F4F7),
    bgSecondary: Color(0xFFE8EAF0),
    bgTertiary: Color(0xFFDFE2E8),
    bgCard: Color(0xFFFFFFFF),
    bgSurface: Color(0xFFF8F9FB),
    bgHover: Color(0xFFE2E5EC),
    borderColor: Color(0xFFE2E5EC),
    borderColorLight: Color(0xFFECEEF2),
    borderColorHover: Color(0xFFC5CBD6),
    textPrimary: Color(0xFF181D27),
    textSecondary: Color(0xFF535862),
    textMuted: Color(0xFF717680),
    textTertiary: Color(0xFF9496A1),
    textInverse: Color(0xFFFFFFFF),
    accentPrimary: Color(0xFFE84562),
    accentPrimaryHover: Color(0xFFD83855),
    accentPrimaryShadow: Color(0xFFB82542),
    accentPrimarySoft: Color(0x14E84562),
    accentSecondary: Color(0xFF7C3AED),
    accentSecondarySoft: Color(0x147C3AED),
    accentTertiary: Color(0xFFD97706),
    colorFire: Color(0xFFEA580C),
    colorDiamond: Color(0xFF0284C7),
    colorGrammar: Color(0xFF10B981),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    wordNewBg: Color(0xFFFFEBF0),
    wordNewText: Color(0xFFC42B47),
    wordLearningBg: Color(0xFFFEF3D6),
    wordLearningText: Color(0xFF8B5700),
    wordKnownBg: Color(0xFFE6F2FF),
    wordKnownText: Color(0xFF0E60B8),
    wordMasteredBg: Color(0xFFE6F9F0),
    wordMasteredText: Color(0xFF15803D),
    levelBeginnerBg: Color(0xFFE6F2FF),
    levelBeginnerText: Color(0xFF0E60B8),
    levelBeginnerBorder: Color(0x330E60B8),
    levelElementaryBg: Color(0xFFE2F6F9),
    levelElementaryText: Color(0xFF087382),
    levelElementaryBorder: Color(0x33087382),
    levelIntermediateBg: Color(0xFFFEF3D6),
    levelIntermediateText: Color(0xFF8B5700),
    levelIntermediateBorder: Color(0x338B5700),
    levelUpperBg: Color(0xFFFFF0E5),
    levelUpperText: Color(0xFFA74A00),
    levelUpperBorder: Color(0x33A74A00),
    levelAdvancedBg: Color(0xFFFFEBF0),
    levelAdvancedText: Color(0xFFC42B47),
    levelAdvancedBorder: Color(0x33C42B47),
  );
}

class LevelColorInfo {
  final Color bg;
  final Color text;
  final Color border;

  const LevelColorInfo({
    required this.bg,
    required this.text,
    required this.border,
  });

  static String cleanLevel(String raw) {
    if (raw.isEmpty) return 'ALL';
    if (raw.contains('{') || raw.contains('level:')) {
      final match = RegExp(r'level:\s*([^,}]+)').firstMatch(raw);
      if (match != null) {
        return match.group(1)?.trim() ?? raw;
      }
      final tierMatch = RegExp(r'tier:\s*([^,}]+)').firstMatch(raw);
      if (tierMatch != null) {
        return tierMatch.group(1)?.trim().toUpperCase() ?? raw;
      }
    }
    return raw.trim();
  }

  static LevelColorInfo forLevel(String levelStr, {bool isDark = true}) {
    final palette = isDark ? VocaColorPalette.dark : VocaColorPalette.light;
    final clean = cleanLevel(levelStr);
    final l = clean.toUpperCase().replaceAll(' ', '');

    if (l.contains('N5') ||
        l.contains('HSK1') ||
        l.contains('TOPIK1') ||
        l.contains('A1') ||
        l.contains('BEGINNER')) {
      return LevelColorInfo(
        bg: palette.levelBeginnerBg,
        text: palette.levelBeginnerText,
        border: palette.levelBeginnerBorder,
      );
    }
    if (l.contains('N4') ||
        l.contains('HSK2') ||
        l.contains('TOPIK2') ||
        l.contains('A2') ||
        l.contains('ELEMENTARY')) {
      return LevelColorInfo(
        bg: palette.levelElementaryBg,
        text: palette.levelElementaryText,
        border: palette.levelElementaryBorder,
      );
    }
    if (l.contains('N3') ||
        l.contains('HSK3') ||
        l.contains('HSK4') ||
        l.contains('TOPIK3') ||
        l.contains('TOPIK4') ||
        l.contains('B1') ||
        l.contains('INTERMEDIATE')) {
      return LevelColorInfo(
        bg: palette.levelIntermediateBg,
        text: palette.levelIntermediateText,
        border: palette.levelIntermediateBorder,
      );
    }
    if (l.contains('N2') ||
        l.contains('HSK5') ||
        l.contains('TOPIK5') ||
        l.contains('B2') ||
        l.contains('UPPER')) {
      return LevelColorInfo(
        bg: palette.levelUpperBg,
        text: palette.levelUpperText,
        border: palette.levelUpperBorder,
      );
    }
    if (l.contains('N1') ||
        l.contains('HSK6') ||
        l.contains('TOPIK6') ||
        l.contains('C1') ||
        l.contains('C2') ||
        l.contains('ADVANCED')) {
      return LevelColorInfo(
        bg: palette.levelAdvancedBg,
        text: palette.levelAdvancedText,
        border: palette.levelAdvancedBorder,
      );
    }
    return LevelColorInfo(
      bg: palette.levelBeginnerBg,
      text: palette.levelBeginnerText,
      border: palette.levelBeginnerBorder,
    );
  }
}

class VocaTheme {
  /// Theme-aware color accessor based on the current context's brightness
  static VocaColorPalette colors(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? VocaColorPalette.dark
        : VocaColorPalette.light;
  }

  /// Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VocaColorPalette.dark.bgPrimary,
      canvasColor: VocaColorPalette.dark.bgPrimary,
      cardColor: VocaColorPalette.dark.bgCard,
      dividerColor: VocaColorPalette.dark.borderColor,
      colorScheme: ColorScheme.dark(
        primary: VocaColorPalette.dark.accentPrimary,
        onPrimary: Colors.white,
        secondary: VocaColorPalette.dark.accentSecondary,
        onSecondary: Colors.white,
        surface: VocaColorPalette.dark.bgCard,
        onSurface: VocaColorPalette.dark.textPrimary,
        error: VocaColorPalette.dark.error,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: VocaColorPalette.dark.bgPrimary,
        foregroundColor: VocaColorPalette.dark.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: VocaColorPalette.dark.bgCard,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: VocaColorPalette.dark.bgCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: VocaColorPalette.dark.bgSecondary,
        selectedItemColor: VocaColorPalette.dark.accentPrimary,
        unselectedItemColor: VocaColorPalette.dark.textMuted,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80.0,
        backgroundColor: VocaColorPalette.dark.bgSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: VocaColorPalette.dark.accentPrimarySoft,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: VocaColorPalette.dark.textPrimary,
              letterSpacing: 0.18,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: VocaColorPalette.dark.textMuted,
            letterSpacing: 0.18,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              size: 22,
              color: VocaColorPalette.dark.accentPrimary,
            );
          }
          return IconThemeData(
            size: 22,
            color: VocaColorPalette.dark.textSecondary,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: VocaColorPalette.dark.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: VocaColorPalette.dark.borderColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VocaColorPalette.dark.accentPrimary,
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
          foregroundColor: VocaColorPalette.dark.textPrimary,
          side: BorderSide(color: VocaColorPalette.dark.borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: VocaColorPalette.dark.textPrimary),
        bodyMedium: TextStyle(color: VocaColorPalette.dark.textPrimary),
        bodySmall: TextStyle(color: VocaColorPalette.dark.textSecondary),
        titleLarge: TextStyle(color: VocaColorPalette.dark.textPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: VocaColorPalette.dark.textPrimary, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: VocaColorPalette.dark.textSecondary, fontWeight: FontWeight.w500),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return VocaColorPalette.dark.textTertiary;
          }
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return VocaColorPalette.dark.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return VocaColorPalette.dark.bgTertiary;
          }
          if (states.contains(WidgetState.selected)) {
            return VocaColorPalette.dark.accentPrimary;
          }
          return VocaColorPalette.dark.bgSurface;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return VocaColorPalette.dark.borderColor;
        }),
        thumbIcon: const WidgetStatePropertyAll<Icon?>(null),
      ),
    );
  }

  /// Light Theme Configuration (Crisp Porcelain - Apple & Linear Inspired)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: VocaColorPalette.light.bgPrimary,
      canvasColor: VocaColorPalette.light.bgPrimary,
      cardColor: VocaColorPalette.light.bgCard,
      dividerColor: VocaColorPalette.light.borderColor,
      colorScheme: ColorScheme.light(
        primary: VocaColorPalette.light.accentPrimary,
        onPrimary: Colors.white,
        secondary: VocaColorPalette.light.accentSecondary,
        onSecondary: Colors.white,
        surface: VocaColorPalette.light.bgCard,
        onSurface: VocaColorPalette.light.textPrimary,
        error: VocaColorPalette.light.error,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: VocaColorPalette.light.bgPrimary,
        foregroundColor: VocaColorPalette.light.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: VocaColorPalette.light.bgCard,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: VocaColorPalette.light.bgCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: VocaColorPalette.light.bgSecondary,
        selectedItemColor: VocaColorPalette.light.accentPrimary,
        unselectedItemColor: VocaColorPalette.light.textMuted,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80.0,
        backgroundColor: VocaColorPalette.light.bgSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: VocaColorPalette.light.accentPrimarySoft,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: VocaColorPalette.light.textPrimary,
              letterSpacing: 0.18,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: VocaColorPalette.light.textMuted,
            letterSpacing: 0.18,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              size: 22,
              color: VocaColorPalette.light.accentPrimary,
            );
          }
          return IconThemeData(
            size: 22,
            color: VocaColorPalette.light.textSecondary,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: VocaColorPalette.light.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: VocaColorPalette.light.borderColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VocaColorPalette.light.accentPrimary,
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
          foregroundColor: VocaColorPalette.light.textPrimary,
          side: BorderSide(color: VocaColorPalette.light.borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: VocaColorPalette.light.textPrimary),
        bodyMedium: TextStyle(color: VocaColorPalette.light.textPrimary),
        bodySmall: TextStyle(color: VocaColorPalette.light.textSecondary),
        titleLarge: TextStyle(color: VocaColorPalette.light.textPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: VocaColorPalette.light.textPrimary, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: VocaColorPalette.light.textSecondary, fontWeight: FontWeight.w500),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return VocaColorPalette.light.textTertiary;
          }
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return VocaColorPalette.light.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return VocaColorPalette.light.bgTertiary;
          }
          if (states.contains(WidgetState.selected)) {
            return VocaColorPalette.light.accentPrimary;
          }
          return VocaColorPalette.light.bgHover;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return VocaColorPalette.light.borderColor;
        }),
        thumbIcon: const WidgetStatePropertyAll<Icon?>(null),
      ),
    );
  }
}

/// Context extensions for easy access to theme colors and state
extension VocaThemeContextExtension on BuildContext {
  VocaColorPalette get vocaColors => VocaTheme.colors(this);
  VocaColorPalette get colors => VocaTheme.colors(this);
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
