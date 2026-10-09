// lib/ui/gamification/widgets/rpg_shield_crest.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';

/// Custom clipper that traces the authentic RPG Heater Shield silhouette:
/// polygon(50% 100%, 0 78%, 0 8%, 15% 0, 85% 0, 100% 8%, 100% 78%)
class RpgShieldClipper extends CustomClipper<Path> {
  const RpgShieldClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(0.15 * w, 0.0);
    path.lineTo(0.85 * w, 0.0);
    path.lineTo(w, 0.08 * h);
    path.lineTo(w, 0.78 * h);
    path.lineTo(0.50 * w, h);
    path.lineTo(0.0, 0.78 * h);
    path.lineTo(0.0, 0.08 * h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// 10 canonical RPG progression tiers + semantic variants for streaks, diamonds, quests.
enum RpgCrestStyle {
  stone,
  bronze,
  silver,
  gold,
  platinum,
  emerald,
  diamond,
  master,
  grandmaster,
  mythic,
  // Semantic Campfire & Quest variants
  flameCold,
  flameEmber,
  flameBlaze,
  flameBeacon,
  quest,
  ;

  /// Resolves the tier from a level (1 to 50)
  static RpgCrestStyle forLevel(int level) {
    final lvl = level.clamp(1, 50);
    if (lvl <= 5) return RpgCrestStyle.stone;
    if (lvl <= 10) return RpgCrestStyle.bronze;
    if (lvl <= 15) return RpgCrestStyle.silver;
    if (lvl <= 20) return RpgCrestStyle.gold;
    if (lvl <= 25) return RpgCrestStyle.platinum;
    if (lvl <= 30) return RpgCrestStyle.emerald;
    if (lvl <= 35) return RpgCrestStyle.diamond;
    if (lvl <= 40) return RpgCrestStyle.master;
    if (lvl <= 45) return RpgCrestStyle.grandmaster;
    return RpgCrestStyle.mythic;
  }

  /// Resolves the campfire hearth stage from streak days
  static RpgCrestStyle forStreak(int streakDays) {
    if (streakDays <= 0) return RpgCrestStyle.flameCold;
    if (streakDays < 7) return RpgCrestStyle.flameEmber;
    if (streakDays < 30) return RpgCrestStyle.flameBlaze;
    return RpgCrestStyle.flameBeacon;
  }

  /// Display name for the tier / stage
  String get displayName {
    switch (this) {
      case RpgCrestStyle.stone:
        return 'Stone';
      case RpgCrestStyle.bronze:
        return 'Bronze';
      case RpgCrestStyle.silver:
        return 'Silver';
      case RpgCrestStyle.gold:
        return 'Gold';
      case RpgCrestStyle.platinum:
        return 'Platinum';
      case RpgCrestStyle.emerald:
        return 'Emerald';
      case RpgCrestStyle.diamond:
        return 'Diamond';
      case RpgCrestStyle.master:
        return 'Master';
      case RpgCrestStyle.grandmaster:
        return 'Grandmaster';
      case RpgCrestStyle.mythic:
        return 'Mythic';
      case RpgCrestStyle.flameCold:
        return 'Cold Slate';
      case RpgCrestStyle.flameEmber:
        return 'Kindle Ember';
      case RpgCrestStyle.flameBlaze:
        return 'Blazing Hearth';
      case RpgCrestStyle.flameBeacon:
        return 'Eternal Beacon';
      case RpgCrestStyle.quest:
        return 'Questmaster';
    }
  }

  /// Linear gradient for the shield outer rim
  Gradient get rimGradient {
    switch (this) {
      case RpgCrestStyle.stone:
        return const LinearGradient(
          begin: Alignment(-0.8, -0.6),
          end: Alignment(0.8, 0.6),
          colors: [Color(0xFF94A3B8), Color(0xFF64748B), Color(0xFF334155)],
          stops: [0.0, 0.40, 1.0],
        );
      case RpgCrestStyle.bronze:
        return const LinearGradient(
          begin: Alignment(-0.8, -0.6),
          end: Alignment(0.8, 0.6),
          colors: [Color(0xFFF59E0B), Color(0xFFB45309), Color(0xFF78350F)],
          stops: [0.0, 0.40, 1.0],
        );
      case RpgCrestStyle.silver:
        return const LinearGradient(
          begin: Alignment(-0.8, -0.6),
          end: Alignment(0.8, 0.6),
          colors: [Color(0xFFF8FAFC), Color(0xFFCBD5E1), Color(0xFF475569)],
          stops: [0.0, 0.35, 1.0],
        );
      case RpgCrestStyle.gold:
        return const LinearGradient(
          begin: Alignment(-0.8, -0.6),
          end: Alignment(0.8, 0.6),
          colors: [Color(0xFFFEF08A), Color(0xFFF59E0B), Color(0xFFB45309)],
          stops: [0.0, 0.40, 1.0],
        );
      case RpgCrestStyle.platinum:
        return const LinearGradient(
          begin: Alignment(-0.8, -0.6),
          end: Alignment(0.8, 0.6),
          colors: [Color(0xFFA5F3FC), Color(0xFF06B6D4), Color(0xFF0E7490)],
          stops: [0.0, 0.40, 1.0],
        );
      case RpgCrestStyle.emerald:
        return const LinearGradient(
          begin: Alignment(-0.8, -0.6),
          end: Alignment(0.8, 0.6),
          colors: [Color(0xFFA7F3D0), Color(0xFF10B981), Color(0xFF047857)],
          stops: [0.0, 0.40, 1.0],
        );
      case RpgCrestStyle.diamond:
        return const LinearGradient(
          begin: Alignment(-0.8, -0.6),
          end: Alignment(0.8, 0.6),
          colors: [Color(0xFFBAE6FD), Color(0xFF38BDF8), Color(0xFF818CF8), Color(0xFFC084FC)],
          stops: [0.0, 0.30, 0.70, 1.0],
        );
      case RpgCrestStyle.master:
        return const LinearGradient(
          begin: Alignment(-0.8, -0.6),
          end: Alignment(0.8, 0.6),
          colors: [Color(0xFFE9D5FF), Color(0xFF8B5CF6), Color(0xFF581C87)],
          stops: [0.0, 0.40, 1.0],
        );
      case RpgCrestStyle.grandmaster:
        return const LinearGradient(
          begin: Alignment(-0.8, -0.6),
          end: Alignment(0.8, 0.6),
          colors: [Color(0xFFFECACA), Color(0xFFEF4444), Color(0xFF991B1B)],
          stops: [0.0, 0.40, 1.0],
        );
      case RpgCrestStyle.mythic:
        return const LinearGradient(
          begin: Alignment(-0.8, -0.6),
          end: Alignment(0.8, 0.6),
          colors: [Color(0xFFFEF08A), Color(0xFFF43F5E), Color(0xFF8B5CF6), Color(0xFF38BDF8)],
          stops: [0.0, 0.35, 0.70, 1.0],
        );
      case RpgCrestStyle.flameCold:
        return const LinearGradient(
          begin: Alignment(-0.8, -0.6),
          end: Alignment(0.8, 0.6),
          colors: [Color(0xFF94A3B8), Color(0xFF64748B), Color(0xFF334155)],
          stops: [0.0, 0.40, 1.0],
        );
      case RpgCrestStyle.flameEmber:
        return const LinearGradient(
          begin: Alignment(-0.8, -0.6),
          end: Alignment(0.8, 0.6),
          colors: [Color(0xFFF97316), Color(0xFFEA580C), Color(0xFF7C2D12)],
          stops: [0.0, 0.40, 1.0],
        );
      case RpgCrestStyle.flameBlaze:
        return const LinearGradient(
          begin: Alignment(-0.8, -0.6),
          end: Alignment(0.8, 0.6),
          colors: [Color(0xFFFB923C), Color(0xFFF97316), Color(0xFF9A3412)],
          stops: [0.0, 0.40, 1.0],
        );
      case RpgCrestStyle.flameBeacon:
        return const LinearGradient(
          begin: Alignment(-0.8, -0.6),
          end: Alignment(0.8, 0.6),
          colors: [Color(0xFF38BDF8), Color(0xFF8B5CF6), Color(0xFFEC4899)],
          stops: [0.0, 0.45, 1.0],
        );
      case RpgCrestStyle.quest:
        return const LinearGradient(
          begin: Alignment(-0.8, -0.6),
          end: Alignment(0.8, 0.6),
          colors: [Color(0xFF6EE7B7), Color(0xFF10B981), Color(0xFF047857)],
          stops: [0.0, 0.40, 1.0],
        );
    }
  }

  /// Radial gradient for the inner shield plate
  Gradient get innerGradient {
    switch (this) {
      case RpgCrestStyle.stone:
      case RpgCrestStyle.flameCold:
        return const RadialGradient(
          center: Alignment(0.0, -0.5),
          radius: 0.9,
          colors: [Color(0xFF475569), Color(0xFF1E293B)],
        );
      case RpgCrestStyle.bronze:
        return const RadialGradient(
          center: Alignment(0.0, -0.5),
          radius: 0.9,
          colors: [Color(0xFF92400E), Color(0xFF451A03)],
        );
      case RpgCrestStyle.silver:
        return const RadialGradient(
          center: Alignment(0.0, -0.5),
          radius: 0.9,
          colors: [Color(0xFF64748B), Color(0xFF1E293B)],
        );
      case RpgCrestStyle.gold:
        return const RadialGradient(
          center: Alignment(0.0, -0.5),
          radius: 0.9,
          colors: [Color(0xFFB45309), Color(0xFF451A03)],
        );
      case RpgCrestStyle.platinum:
        return const RadialGradient(
          center: Alignment(0.0, -0.5),
          radius: 0.9,
          colors: [Color(0xFF0891B2), Color(0xFF164E63)],
        );
      case RpgCrestStyle.emerald:
        return const RadialGradient(
          center: Alignment(0.0, -0.5),
          radius: 0.9,
          colors: [Color(0xFF059669), Color(0xFF064E3B)],
        );
      case RpgCrestStyle.diamond:
        return const RadialGradient(
          center: Alignment(0.0, -0.5),
          radius: 0.9,
          colors: [Color(0xFF0369A1), Color(0xFF1E1B4B)],
        );
      case RpgCrestStyle.master:
        return const RadialGradient(
          center: Alignment(0.0, -0.5),
          radius: 0.9,
          colors: [Color(0xFF7C3AED), Color(0xFF3B0764)],
        );
      case RpgCrestStyle.grandmaster:
        return const RadialGradient(
          center: Alignment(0.0, -0.5),
          radius: 0.9,
          colors: [Color(0xFFDC2626), Color(0xFF450A0A)],
        );
      case RpgCrestStyle.mythic:
        return const RadialGradient(
          center: Alignment(0.0, -0.5),
          radius: 0.9,
          colors: [Color(0xFF831843), Color(0xFF180536)],
        );
      case RpgCrestStyle.flameEmber:
        return const RadialGradient(
          center: Alignment(0.0, -0.5),
          radius: 0.9,
          colors: [Color(0xFF9A3412), Color(0xFF431407)],
        );
      case RpgCrestStyle.flameBlaze:
        return const RadialGradient(
          center: Alignment(0.0, -0.5),
          radius: 0.9,
          colors: [Color(0xFFC2410C), Color(0xFF431407)],
        );
      case RpgCrestStyle.flameBeacon:
        return const RadialGradient(
          center: Alignment(0.0, -0.5),
          radius: 0.9,
          colors: [Color(0xFF0369A1), Color(0xFF2E1065)],
        );
      case RpgCrestStyle.quest:
        return const RadialGradient(
          center: Alignment(0.0, -0.5),
          radius: 0.9,
          colors: [Color(0xFF065F46), Color(0xFF022C22)],
        );
    }
  }

  /// Inner specular border color
  Color get innerBorderColor {
    switch (this) {
      case RpgCrestStyle.stone:
      case RpgCrestStyle.flameCold:
        return const Color(0x8094A3B8);
      case RpgCrestStyle.bronze:
        return const Color(0x80F59E0B);
      case RpgCrestStyle.silver:
        return const Color(0xB3FFFFFF);
      case RpgCrestStyle.gold:
        return const Color(0xCCFEF08A);
      case RpgCrestStyle.platinum:
        return const Color(0xB367E8F9);
      case RpgCrestStyle.emerald:
        return const Color(0xB36EE7B7);
      case RpgCrestStyle.diamond:
        return const Color(0xD9E0F2FE);
      case RpgCrestStyle.master:
        return const Color(0xBFC4B5FD);
      case RpgCrestStyle.grandmaster:
        return const Color(0xCCFCA5A5);
      case RpgCrestStyle.mythic:
        return const Color(0xE6FDE047);
      case RpgCrestStyle.flameEmber:
        return const Color(0xBFFB923C);
      case RpgCrestStyle.flameBlaze:
        return const Color(0xD9FDBA74);
      case RpgCrestStyle.flameBeacon:
        return const Color(0xD97DD3FC);
      case RpgCrestStyle.quest:
        return const Color(0xBFA7F3D0);
    }
  }

  /// Ambient glow & drop-shadow color
  Color get glowColor {
    switch (this) {
      case RpgCrestStyle.stone:
      case RpgCrestStyle.flameCold:
        return const Color(0x4D64748B);
      case RpgCrestStyle.bronze:
        return const Color(0x59D97706);
      case RpgCrestStyle.silver:
        return const Color(0x5994A3B8);
      case RpgCrestStyle.gold:
        return const Color(0x73F59E0B);
      case RpgCrestStyle.platinum:
        return const Color(0x6606B6D4);
      case RpgCrestStyle.emerald:
        return const Color(0x6610B981);
      case RpgCrestStyle.diamond:
        return const Color(0x8038BDF8);
      case RpgCrestStyle.master:
        return const Color(0x738B5CF6);
      case RpgCrestStyle.grandmaster:
        return const Color(0x80EF4444);
      case RpgCrestStyle.mythic:
        return const Color(0x8CF43F5E);
      case RpgCrestStyle.flameEmber:
        return const Color(0x80F97316);
      case RpgCrestStyle.flameBlaze:
        return const Color(0x99F97316);
      case RpgCrestStyle.flameBeacon:
        return const Color(0xA638BDF8);
      case RpgCrestStyle.quest:
        return const Color(0x8010B981);
    }
  }

  /// Default icon foreground tint
  Color get iconColor {
    switch (this) {
      case RpgCrestStyle.stone:
        return const Color(0xFFF1F5F9);
      case RpgCrestStyle.bronze:
        return const Color(0xFFFEF3C7);
      case RpgCrestStyle.silver:
        return Colors.white;
      case RpgCrestStyle.gold:
        return const Color(0xFFFFFBEB);
      case RpgCrestStyle.platinum:
        return const Color(0xFFCFFAFE);
      case RpgCrestStyle.emerald:
        return const Color(0xFFECFDF5);
      case RpgCrestStyle.diamond:
        return const Color(0xFFF0FDF4);
      case RpgCrestStyle.master:
        return const Color(0xFFFAF5FF);
      case RpgCrestStyle.grandmaster:
        return const Color(0xFFFEF2F2);
      case RpgCrestStyle.mythic:
        return Colors.white;
      case RpgCrestStyle.flameCold:
        return const Color(0xFFCBD5E1);
      case RpgCrestStyle.flameEmber:
        return const Color(0xFFFFEDD5);
      case RpgCrestStyle.flameBlaze:
        return const Color(0xFFFFF7ED);
      case RpgCrestStyle.flameBeacon:
        return const Color(0xFFF0FDF4);
      case RpgCrestStyle.quest:
        return const Color(0xFFECFDF5);
    }
  }

  /// Returns high-contrast semantic accent color directly from active VocaColorPalette.
  /// Zero hardcoded colors — fully theme-driven and WCAG AAA/AA compliant.
  Color accentColor(VocaColorPalette colors) {
    switch (this) {
      case RpgCrestStyle.stone:
      case RpgCrestStyle.flameCold:
        return colors.isDark ? colors.textSecondary : colors.textPrimary;
      case RpgCrestStyle.bronze:
        return colors.warning;
      case RpgCrestStyle.silver:
        return colors.isDark ? colors.accentSecondary : colors.textPrimary;
      case RpgCrestStyle.gold:
        return colors.accentTertiary;
      case RpgCrestStyle.platinum:
        return colors.colorDiamond;
      case RpgCrestStyle.emerald:
      case RpgCrestStyle.quest:
        return colors.colorGrammar;
      case RpgCrestStyle.diamond:
      case RpgCrestStyle.flameBeacon:
        return colors.colorDiamond;
      case RpgCrestStyle.master:
        return colors.accentSecondary;
      case RpgCrestStyle.grandmaster:
        return colors.error;
      case RpgCrestStyle.mythic:
        return colors.accentPrimary;
      case RpgCrestStyle.flameEmber:
      case RpgCrestStyle.flameBlaze:
        return colors.colorFire;
    }
  }
}

/// Reusable RPG Heater Shield Crest custom widget matching 1:1 with web's `rpg-shield-crest`.
class RpgShieldCrest extends StatelessWidget {
  final double width;
  final double height;
  final RpgCrestStyle style;
  final Widget? child;
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;
  final bool showGlow;
  final double innerInset;

  const RpgShieldCrest({
    super.key,
    this.width = 60,
    this.height = 68,
    this.style = RpgCrestStyle.bronze,
    this.child,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.showGlow = true,
    this.innerInset = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    const clipper = RpgShieldClipper();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: style.glowColor,
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Outer rim polygon
          ClipPath(
            clipper: clipper,
            child: Container(
              decoration: BoxDecoration(
                gradient: style.rimGradient,
              ),
            ),
          ),

          // 2. Inner specular inset plate
          Positioned(
            left: innerInset,
            right: innerInset,
            top: innerInset,
            bottom: innerInset,
            child: ClipPath(
              clipper: clipper,
              child: Container(
                decoration: BoxDecoration(
                  gradient: style.innerGradient,
                  border: Border.all(
                    color: style.innerBorderColor,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),

          // 3. Top specular light reflection highlight (upper 46%)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: height * 0.46,
            child: ClipPath(
              clipper: clipper,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x61FFFFFF), // 38% white
                      Color(0x05FFFFFF), // 2% white
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Center icon / widget content
          Center(
            child: child ??
                (icon != null
                    ? Icon(
                        icon,
                        size: iconSize ?? (width * 0.45),
                        color: iconColor ?? style.iconColor,
                        shadows: const [
                          Shadow(
                            color: Color(0xA6000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      )
                    : null),
          ),
        ],
      ),
    );
  }
}
