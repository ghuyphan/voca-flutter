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

  // Secondary & Tertiary Accents (Material 3 Harmonized)
  static const Color accentSecondary = Color(0xFFCFBCFF); // M3 Tone 80 Pastel Lavender / Violet
  static const Color accentSecondarySoft = Color(0x26CFBCFF);
  static const Color accentTertiary = Color(0xFFFFB959); // M3 Tone 80 Warm Topaz Gold (XP / Trophy)

  // Gamification & Semantics (Chill Pastel for dark canvas - Apple & Linear Inspired)
  static const Color colorFire = Color(0xFFFDBA74); // Chill pastel apricot flame
  static const Color colorDiamond = Color(0xFF93C5FD); // Chill pastel baby blue diamond
  static const Color colorGrammar = Color(0xFF6EE7B7); // Chill pastel mint teal
  static const Color success = Color(0xFF86EFAC); // Chill pastel matcha green
  static const Color warning = Color(0xFFFDE068); // Chill pastel butter gold
  static const Color error = Color(0xFFFDA4AF); // Chill pastel rose blush

  // Word Mastery Status Colors
  static const Color wordNewBg = Color(0x26FF6B82);
  static const Color wordNewText = Color(0xFFFF8CA0);
  static const Color wordLearningBg = Color(0x26FBBF24);
  static const Color wordLearningText = Color(0xFFFCD34D);
  static const Color wordKnownBg = Color(0x2638BDF8);
  static const Color wordKnownText = Color(0xFF7DD3FC);
  static const Color wordMasteredBg = Color(0x264ADE80);
  static const Color wordMasteredText = Color(0xFF86EFAC);

  // Material 3 Tonal Difficulty Level Colors (Dark Mode M3 Tonal)
  static const Color levelBeginnerBg = Color(0x336366F1);
  static const Color levelBeginnerText = Color(0xFFA5B4FC);
  static const Color levelBeginnerBorder = Color(0x59818CF8);

  static const Color levelElementaryBg = Color(0x3314B8A6);
  static const Color levelElementaryText = Color(0xFF5EEAD4);
  static const Color levelElementaryBorder = Color(0x592DD4BF);

  static const Color levelIntermediateBg = Color(0x33F59E0B);
  static const Color levelIntermediateText = Color(0xFFFCD34D);
  static const Color levelIntermediateBorder = Color(0x59FBBF24);

  static const Color levelUpperBg = Color(0x33F97316);
  static const Color levelUpperText = Color(0xFFFDBA74);
  static const Color levelUpperBorder = Color(0x59FB923C);

  static const Color levelAdvancedBg = Color(0x33F43F5E);
  static const Color levelAdvancedText = Color(0xFFFDA4AF);
  static const Color levelAdvancedBorder = Color(0x59FB7185);

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
    accentSecondary: Color(0xFFCFBCFF),
    accentSecondarySoft: Color(0x26CFBCFF),
    accentTertiary: Color(0xFFFFB959),
    colorFire: Color(0xFFFDBA74),
    colorDiamond: Color(0xFF93C5FD),
    colorGrammar: Color(0xFF6EE7B7),
    success: Color(0xFF86EFAC),
    warning: Color(0xFFFDE068),
    error: Color(0xFFFDA4AF),
    wordNewBg: Color(0x26FF6B82),
    wordNewText: Color(0xFFFF8CA0),
    wordLearningBg: Color(0x26FBBF24),
    wordLearningText: Color(0xFFFCD34D),
    wordKnownBg: Color(0x2638BDF8),
    wordKnownText: Color(0xFF7DD3FC),
    wordMasteredBg: Color(0x264ADE80),
    wordMasteredText: Color(0xFF86EFAC),
    levelBeginnerBg: Color(0x336366F1),
    levelBeginnerText: Color(0xFFA5B4FC),
    levelBeginnerBorder: Color(0x59818CF8),
    levelElementaryBg: Color(0x3314B8A6),
    levelElementaryText: Color(0xFF5EEAD4),
    levelElementaryBorder: Color(0x592DD4BF),
    levelIntermediateBg: Color(0x33F59E0B),
    levelIntermediateText: Color(0xFFFCD34D),
    levelIntermediateBorder: Color(0x59FBBF24),
    levelUpperBg: Color(0x33F97316),
    levelUpperText: Color(0xFFFDBA74),
    levelUpperBorder: Color(0x59FB923C),
    levelAdvancedBg: Color(0x33F43F5E),
    levelAdvancedText: Color(0xFFFDA4AF),
    levelAdvancedBorder: Color(0x59FB7185),
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
    accentSecondary: Color(0xFF6750A4), // M3 Tone 40 Iris/Violet (Google M3 Baseline)
    accentSecondarySoft: Color(0x1F6750A4),
    accentTertiary: Color(0xFF855300), // M3 Tone 40 Topaz Gold (Trophy / Star / XP)
    colorFire: Color(0xFFC2410C), // M3 Tone 40 deep warm flame on light canvas
    colorDiamond: Color(0xFF0284C7), // M3 Tone 40 deep sky diamond on light canvas
    colorGrammar: Color(0xFF0F766E), // M3 Tone 40 deep mint teal on light canvas
    success: Color(0xFF15803D), // M3 Tone 40 accessible green on light canvas
    warning: Color(0xFFB45309), // M3 Tone 40 accessible dark amber on light canvas (WCAG AA >= 4.5:1)
    error: Color(0xFFDC2626), // M3 Tone 40 accessible crimson on light canvas
    wordNewBg: Color(0xFFFFE4E6),
    wordNewText: Color(0xFFBE123C),
    wordLearningBg: Color(0xFFFEF9C3), // Fresh warm gold container
    wordLearningText: Color(0xFF854D0E), // Deep gold amber (WCAG AAA >= 7:1)
    wordKnownBg: Color(0xFFE0F2FE),
    wordKnownText: Color(0xFF0369A1),
    wordMasteredBg: Color(0xFFDCFCE7),
    wordMasteredText: Color(0xFF15803D),
    levelBeginnerBg: Color(0xFFEEF2FF), // M3 Indigo Tone 95
    levelBeginnerText: Color(0xFF3730A3), // M3 Indigo Tone 30 (WCAG AAA >= 7:1)
    levelBeginnerBorder: Color(0xFFC7D2FE), // M3 Indigo Tone 80
    levelElementaryBg: Color(0xFFF0FDFA), // M3 Teal Tone 95
    levelElementaryText: Color(0xFF0F766E), // M3 Teal Tone 30 (WCAG AAA >= 7:1)
    levelElementaryBorder: Color(0xFF99F6E4), // M3 Teal Tone 80
    levelIntermediateBg: Color(0xFFFEF9C3), // M3 Amber Tone 95
    levelIntermediateText: Color(0xFF854D0E), // M3 Amber Tone 30 (WCAG AAA >= 7:1)
    levelIntermediateBorder: Color(0xFFFDE047), // M3 Amber Tone 80
    levelUpperBg: Color(0xFFFFF7ED), // M3 Orange Tone 95
    levelUpperText: Color(0xFF9A3412), // M3 Orange Tone 30 (WCAG AAA >= 7:1)
    levelUpperBorder: Color(0xFFFED7AA), // M3 Orange Tone 80
    levelAdvancedBg: Color(0xFFFFF1F2), // M3 Rose Tone 95
    levelAdvancedText: Color(0xFF9F1239), // M3 Rose Tone 30 (WCAG AAA >= 7:1)
    levelAdvancedBorder: Color(0xFFFECDD3), // M3 Rose Tone 80
  );
}

class LevelColorInfo {
  final Color bg;
  final Color text;
  final Color border;
  final Color solidBg;
  final Color solidText;

  const LevelColorInfo({
    required this.bg,
    required this.text,
    required this.border,
    required this.solidBg,
    required this.solidText,
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
        solidBg: isDark ? const Color(0xFF9BCEFF) : const Color(0xFF2563EB),
        solidText: isDark ? const Color(0xFF0F172A) : Colors.white,
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
        solidBg: isDark ? const Color(0xFF67E8F9) : const Color(0xFF0891B2),
        solidText: isDark ? const Color(0xFF042F2E) : Colors.white,
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
        solidBg: isDark ? const Color(0xFFFDE068) : const Color(0xFFD97706),
        solidText: isDark ? const Color(0xFF451A03) : Colors.white,
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
        solidBg: isDark ? const Color(0xFFFDBA74) : const Color(0xFFEA580C),
        solidText: isDark ? const Color(0xFF431407) : Colors.white,
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
        solidBg: isDark ? const Color(0xFFFFA4B5) : const Color(0xFFE11D48),
        solidText: isDark ? const Color(0xFF4C0519) : Colors.white,
      );
    }
    return LevelColorInfo(
      bg: palette.levelBeginnerBg,
      text: palette.levelBeginnerText,
      border: palette.levelBeginnerBorder,
      solidBg: isDark ? const Color(0xFF9BCEFF) : const Color(0xFF2563EB),
      solidText: isDark ? const Color(0xFF0F172A) : Colors.white,
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
        onPrimary: const Color(0xFF5C0018),
        primaryContainer: const Color(0xFF7A142A),
        onPrimaryContainer: const Color(0xFFFFD9DF),
        secondary: VocaColorPalette.dark.accentSecondary,
        onSecondary: const Color(0xFF381E72),
        secondaryContainer: const Color(0xFF4F378B),
        onSecondaryContainer: const Color(0xFFEADDFF),
        tertiary: VocaColorPalette.dark.accentTertiary,
        onTertiary: const Color(0xFF452B00),
        tertiaryContainer: const Color(0xFF633F00),
        onTertiaryContainer: const Color(0xFFFFDDB4),
        surface: VocaColorPalette.dark.bgPrimary,
        onSurface: VocaColorPalette.dark.textPrimary,
        onSurfaceVariant: VocaColorPalette.dark.textSecondary,
        surfaceDim: VocaColorPalette.dark.bgPrimary,
        surfaceBright: VocaColorPalette.dark.bgSurface,
        surfaceContainerLowest: VocaColorPalette.dark.bgPrimary,
        surfaceContainerLow: VocaColorPalette.dark.bgSecondary,
        surfaceContainer: VocaColorPalette.dark.bgCard,
        surfaceContainerHigh: VocaColorPalette.dark.bgSurface,
        surfaceContainerHighest: VocaColorPalette.dark.bgHover,
        outline: VocaColorPalette.dark.borderColor,
        outlineVariant: VocaColorPalette.dark.borderColorLight,
        inverseSurface: const Color(0xFFF3F4F7),
        onInverseSurface: const Color(0xFF181D27),
        inversePrimary: VocaColorPalette.light.accentPrimary,
        surfaceTint: Colors.transparent,
        error: VocaColorPalette.dark.error,
        onError: const Color(0xFF601410),
        errorContainer: const Color(0xFF8C1D18),
        onErrorContainer: const Color(0xFFF9DEDC),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: VocaColorPalette.dark.bgCard,
        selectedItemColor: VocaColorPalette.dark.accentPrimary,
        unselectedItemColor: VocaColorPalette.dark.textSecondary,
        elevation: 3.0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80.0,
        backgroundColor: VocaColorPalette.dark.bgCard,
        elevation: 3.0,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        surfaceTintColor: Colors.transparent,
        indicatorColor: VocaColorPalette.dark.accentPrimary.withValues(alpha: 0.22),
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return VocaColorPalette.dark.accentPrimary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return VocaColorPalette.dark.accentPrimary.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return VocaColorPalette.dark.accentPrimary.withValues(alpha: 0.12);
          }
          return null;
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: VocaColorPalette.dark.accentPrimary,
              letterSpacing: 0.2,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: VocaColorPalette.dark.textSecondary,
            letterSpacing: 0.2,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              size: 24,
              color: VocaColorPalette.dark.accentPrimary,
            );
          }
          return IconThemeData(
            size: 24,
            color: VocaColorPalette.dark.textSecondary,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: VocaColorPalette.dark.bgCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: VocaColorPalette.dark.borderColor, width: 0.8),
        ),
        contentTextStyle: TextStyle(
          color: VocaColorPalette.dark.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: VocaColorPalette.dark.accentPrimary,
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
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(VocaColorPalette.dark.bgCard),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          StadiumBorder(side: BorderSide(color: VocaColorPalette.dark.borderColor, width: 1.0)),
        ),
        textStyle: WidgetStatePropertyAll(
          TextStyle(color: VocaColorPalette.dark.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        hintStyle: WidgetStatePropertyAll(
          TextStyle(color: VocaColorPalette.dark.textMuted, fontSize: 13.5, fontWeight: FontWeight.w400),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: VocaColorPalette.dark.bgCard,
        selectedColor: VocaColorPalette.dark.accentPrimarySoft,
        disabledColor: VocaColorPalette.dark.bgTertiary,
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return VocaColorPalette.dark.bgTertiary;
          }
          if (states.contains(WidgetState.selected)) {
            return VocaColorPalette.dark.accentPrimarySoft;
          }
          return VocaColorPalette.dark.bgCard;
        }),
        surfaceTintColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: const StadiumBorder(),
        side: BorderSide(color: VocaColorPalette.dark.borderColor, width: 1.0),
        labelStyle: TextStyle(color: VocaColorPalette.dark.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
        secondaryLabelStyle: TextStyle(color: VocaColorPalette.dark.accentPrimary, fontSize: 12.5, fontWeight: FontWeight.w700),
        checkmarkColor: VocaColorPalette.dark.accentPrimary,
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: VocaColorPalette.dark.textPrimary,
          selectedForegroundColor: VocaColorPalette.dark.textInverse,
          backgroundColor: VocaColorPalette.dark.bgCard,
          foregroundColor: VocaColorPalette.dark.textSecondary,
          side: BorderSide(color: VocaColorPalette.dark.borderColor, width: 1.0),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VocaColorPalette.dark.accentPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: VocaColorPalette.dark.accentPrimary,
        textColor: Colors.white,
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFFE8EAF0),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Color(0xFF0D0F14),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          fontFamily: 'Nunito',
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        verticalOffset: 12,
        triggerMode: TooltipTriggerMode.tap,
        waitDuration: Duration.zero,
        showDuration: const Duration(seconds: 2),
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
        primary: const Color(0xFFD83855),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFFFD9DF),
        onPrimaryContainer: const Color(0xFF3E0011),
        secondary: VocaColorPalette.light.accentSecondary,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFE8DEF8),
        onSecondaryContainer: const Color(0xFF21005D),
        tertiary: VocaColorPalette.light.accentTertiary,
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFFFDDB4),
        onTertiaryContainer: const Color(0xFF2B1700),
        surface: VocaColorPalette.light.bgPrimary,
        onSurface: VocaColorPalette.light.textPrimary,
        onSurfaceVariant: VocaColorPalette.light.textSecondary,
        surfaceDim: VocaColorPalette.light.bgTertiary,
        surfaceBright: VocaColorPalette.light.bgCard,
        surfaceContainerLowest: VocaColorPalette.light.bgCard,
        surfaceContainerLow: VocaColorPalette.light.bgSurface,
        surfaceContainer: VocaColorPalette.light.bgCard,
        surfaceContainerHigh: VocaColorPalette.light.bgSecondary,
        surfaceContainerHighest: VocaColorPalette.light.bgTertiary,
        outline: VocaColorPalette.light.borderColor,
        outlineVariant: VocaColorPalette.light.borderColorLight,
        inverseSurface: const Color(0xFF181B24),
        onInverseSurface: const Color(0xFFF1F3F7),
        inversePrimary: VocaColorPalette.dark.accentPrimary,
        surfaceTint: Colors.transparent,
        error: VocaColorPalette.light.error,
        onError: Colors.white,
        errorContainer: const Color(0xFFF9DEDC),
        onErrorContainer: const Color(0xFF410E0B),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: VocaColorPalette.light.bgCard,
        selectedItemColor: VocaColorPalette.light.accentPrimary,
        unselectedItemColor: VocaColorPalette.light.textSecondary,
        elevation: 3.0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80.0,
        backgroundColor: VocaColorPalette.light.bgCard,
        elevation: 3.0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        indicatorColor: VocaColorPalette.light.accentPrimary.withValues(alpha: 0.14),
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return VocaColorPalette.light.accentPrimary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return VocaColorPalette.light.accentPrimary.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return VocaColorPalette.light.accentPrimary.withValues(alpha: 0.12);
          }
          return null;
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: VocaColorPalette.light.accentPrimary,
              letterSpacing: 0.2,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: VocaColorPalette.light.textSecondary,
            letterSpacing: 0.2,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              size: 24,
              color: VocaColorPalette.light.accentPrimary,
            );
          }
          return IconThemeData(
            size: 24,
            color: VocaColorPalette.light.textSecondary,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: VocaColorPalette.light.bgCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: VocaColorPalette.light.borderColor, width: 0.8),
        ),
        contentTextStyle: TextStyle(
          color: VocaColorPalette.light.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: VocaColorPalette.light.accentPrimary,
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
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(VocaColorPalette.light.bgCard),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          StadiumBorder(side: BorderSide(color: VocaColorPalette.light.borderColor, width: 1.0)),
        ),
        textStyle: WidgetStatePropertyAll(
          TextStyle(color: VocaColorPalette.light.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        hintStyle: WidgetStatePropertyAll(
          TextStyle(color: VocaColorPalette.light.textMuted, fontSize: 13.5, fontWeight: FontWeight.w400),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: VocaColorPalette.light.bgCard,
        selectedColor: VocaColorPalette.light.accentPrimarySoft,
        disabledColor: VocaColorPalette.light.bgTertiary,
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return VocaColorPalette.light.bgTertiary;
          }
          if (states.contains(WidgetState.selected)) {
            return VocaColorPalette.light.accentPrimarySoft;
          }
          return VocaColorPalette.light.bgCard;
        }),
        surfaceTintColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: const StadiumBorder(),
        side: BorderSide(color: VocaColorPalette.light.borderColor, width: 1.0),
        labelStyle: TextStyle(color: VocaColorPalette.light.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
        secondaryLabelStyle: TextStyle(color: VocaColorPalette.light.accentPrimary, fontSize: 12.5, fontWeight: FontWeight.w700),
        checkmarkColor: VocaColorPalette.light.accentPrimary,
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: VocaColorPalette.light.textPrimary,
          selectedForegroundColor: VocaColorPalette.light.textInverse,
          backgroundColor: VocaColorPalette.light.bgCard,
          foregroundColor: VocaColorPalette.light.textSecondary,
          side: BorderSide(color: VocaColorPalette.light.borderColor, width: 1.0),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VocaColorPalette.light.accentPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: VocaColorPalette.light.accentPrimary,
        textColor: Colors.white,
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1E2128),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          fontFamily: 'Nunito',
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        verticalOffset: 12,
        triggerMode: TooltipTriggerMode.tap,
        waitDuration: Duration.zero,
        showDuration: const Duration(seconds: 2),
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
