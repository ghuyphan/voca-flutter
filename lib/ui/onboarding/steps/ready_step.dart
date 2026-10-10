// lib/ui/onboarding/steps/ready_step.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../../../utils/language_utils.dart';
import '../../widgets/voca_sliding_segmented_bar.dart';
import '../models/onboarding_models.dart';
import '../widgets/onboarding_primitives.dart';

/// Step 4: Simplified Personalized Adventurer Pass, Reading Preferences, Theme & Starter Rewards.
/// Direct 1:1 alignment with lingua-tube's `adventurer-license-card` layout & Voca Sliding Segmented Bar:
/// - Holographic adventurer pass card (avatar + rank + language + exam + goal).
/// - Sliding capsule segmented bar for pronunciation guide (for JA/ZH/KO).
/// - Sliding capsule segmented bar for theme selector (System, Light, Dark).
/// - Material 3 Starter Loot reward cache grid (fully localized).
class ReadyStep extends StatelessWidget {
  final String learningLanguage;
  final String selectedLevel;
  final String selectedCompanion;
  final int dailyGoal;
  final String themeMode;
  final String readingDisplayMode;
  final ValueChanged<String>? onThemeChanged;
  final ValueChanged<String>? onReadingDisplayModeChanged;

  const ReadyStep({
    super.key,
    required this.learningLanguage,
    required this.selectedLevel,
    required this.selectedCompanion,
    required this.dailyGoal,
    required this.themeMode,
    this.readingDisplayMode = 'annotated',
    this.onThemeChanged,
    this.onReadingDisplayModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;

    final langOpt = LearningLanguageOption.byCode(learningLanguage);
    final levelOpt = LevelOption.byId(selectedLevel);
    final compOpt = CompanionOption.byId(selectedCompanion);

    final langName = context.t(languageNameKey(langOpt.code), null, langOpt.englishName);
    final rankName = context.t(levelOpt.rankNameKey, null, levelOpt.rankKey);
    final compName = context.t(compOpt.nameKey, null, compOpt.id);
    final examBadge = levelOpt.examBadge(learningLanguage);

    final cleanLang = normalizeLanguageCode(learningLanguage);
    final hasReadingSupport = cleanLang != 'en';

    final previewExample = getReadingDisplayExample(
      readingDisplayMode,
      learningLanguage,
    );

    return OnboardingStepLayout(
      title: context.t('onboarding.starterTitle', null, 'Ready to Learn!'),
      subtitle: context.t(
        'onboarding.starterSubtitle',
        null,
        'Your personalized immersion pass',
      ),
      children: [
        // 1. Holographic Adventurer License Pass (1:1 port of lingua-tube adventurer-license-card)
        _AdventurerPassCard(
          compOpt: compOpt,
          compName: compName,
          rankName: rankName,
          langOpt: langOpt,
          langName: langName,
          examBadge: examBadge,
          dailyGoal: dailyGoal,
          colors: colors,
          isDark: isDark,
        ),

        const SizedBox(height: 14),

        // 2. Pronunciation Guide Selector (Only for script languages: JA, ZH, KO)
        if (hasReadingSupport) ...[
          _PronunciationSelector(
            learningLanguage: cleanLang,
            readingDisplayMode: readingDisplayMode,
            previewExample: previewExample,
            colors: colors,
            isDark: isDark,
            onChanged: onReadingDisplayModeChanged,
          ),
          const SizedBox(height: 14),
        ],

        // 3. Sliding Theme Appearance Selector (System / Light / Dark)
        _ThemeSelector(
          themeMode: themeMode,
          colors: colors,
          isDark: isDark,
          onChanged: onThemeChanged,
        ),

        const SizedBox(height: 14),

        // 4. Compact Starter Loot Reward Cache
        _StarterLootBanner(colors: colors, isDark: isDark),
      ],
    );
  }
}

/// Holographic Guild Adventurer Pass Card
class _AdventurerPassCard extends StatelessWidget {
  final CompanionOption compOpt;
  final String compName;
  final String rankName;
  final LearningLanguageOption langOpt;
  final String langName;
  final String examBadge;
  final int dailyGoal;
  final VocaColorPalette colors;
  final bool isDark;

  const _AdventurerPassCard({
    required this.compOpt,
    required this.compName,
    required this.rankName,
    required this.langOpt,
    required this.langName,
    required this.examBadge,
    required this.dailyGoal,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFEAB308);
    final goalText = context.t(
      'onboarding.minutesPerDay',
      {'minutes': dailyGoal},
      '$dailyGoal min',
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  goldColor.withValues(alpha: 0.14),
                  colors.accentPrimary.withValues(alpha: 0.08),
                  colors.bgCard,
                ]
              : [
                  goldColor.withValues(alpha: 0.10),
                  colors.accentPrimary.withValues(alpha: 0.05),
                  Colors.white,
                ],
        ),
        border: Border.all(
          color: goldColor.withValues(alpha: isDark ? 0.45 : 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: goldColor.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Companion Avatar in Golden Ring
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: goldColor, width: 2.0),
                  color: colors.bgCard,
                  boxShadow: [
                    BoxShadow(
                      color: goldColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: Image.asset(
                    compOpt.avatarAsset,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      compOpt.icon,
                      size: 26,
                      color: compOpt.color,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: goldColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Lv.1',
                    style: TextStyle(
                      color: Color(0xFF422006),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Right: License Info & Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Tag
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 12,
                      color: goldColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.t('onboarding.guildCharter', null, 'Voca Guild Charter').toUpperCase(),
                      style: TextStyle(
                        color: isDark ? goldColor : const Color(0xFFB45309),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Name & Rank
                Text(
                  '$rankName • $compName',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Badges Row
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _MiniChip(
                      icon: RoundFlag(asset: langOpt.flagAsset, size: 14),
                      label: langName,
                      colors: colors,
                    ),
                    _MiniChip(
                      label: examBadge,
                      colors: colors,
                    ),
                    _MiniChip(
                      icon: const Icon(
                        Icons.local_fire_department_rounded,
                        size: 13,
                        color: Color(0xFFEA580C),
                      ),
                      label: goalText,
                      colors: colors,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final Widget? icon;
  final String label;
  final VocaColorPalette colors;

  const _MiniChip({
    this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.bgCard.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colors.borderColorLight.withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sliding Capsule Pronunciation Guide Selector
class _PronunciationSelector extends StatelessWidget {
  final String learningLanguage;
  final String readingDisplayMode;
  final String? previewExample;
  final VocaColorPalette colors;
  final bool isDark;
  final ValueChanged<String>? onChanged;

  const _PronunciationSelector({
    required this.learningLanguage,
    required this.readingDisplayMode,
    required this.previewExample,
    required this.colors,
    required this.isDark,
    required this.onChanged,
  });

  List<({String mode, String label})> _getModes(BuildContext context) {
    final offLabel = context.t('onboarding.readingModeOff', null, 'Off');
    switch (learningLanguage) {
      case 'ja':
        return [
          (
            mode: 'annotated',
            label: context.t('onboarding.readingModeFurigana', null, 'Furigana'),
          ),
          (
            mode: 'romanized',
            label: context.t('onboarding.readingModeRomaji', null, 'Romaji'),
          ),
          (
            mode: 'reading',
            label: context.t('onboarding.readingModeKana', null, 'Kana'),
          ),
          (
            mode: 'native',
            label: offLabel,
          ),
        ];
      case 'zh':
        return [
          (
            mode: 'annotated',
            label: context.t('onboarding.readingModePinyin', null, 'Pinyin'),
          ),
          (
            mode: 'reading',
            label: context.t('settings.pinyinOnly', null, 'Pinyin only'),
          ),
          (
            mode: 'native',
            label: offLabel,
          ),
        ];
      case 'ko':
        return [
          (
            mode: 'annotated',
            label: context.t('onboarding.readingModeRomaji', null, 'Romaji'),
          ),
          (
            mode: 'reading',
            label: context.t('settings.romanizationOnly', null, 'Romaji only'),
          ),
          (
            mode: 'native',
            label: offLabel,
          ),
        ];
      default:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final modes = _getModes(context);
    final validModes = modes.map((m) => m.mode).toSet();
    final effectiveMode = validModes.contains(readingDisplayMode)
        ? readingDisplayMode
        : (modes.isNotEmpty ? modes.first.mode : 'annotated');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColorLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with live preview
          Row(
            children: [
              Icon(Icons.subtitles_rounded, size: 16, color: colors.accentPrimary),
              const SizedBox(width: 6),
              Text(
                context.t('settings.readingStyle', null, 'Pronunciation Guide'),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (previewExample != null)
                Text(
                  previewExample!,
                  style: TextStyle(
                    color: colors.accentPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Sliding Segmented Capsule Bar
          VocaSlidingSegmentedBar(
            values: modes.map((m) => m.mode).toList(),
            labels: modes.map((m) => m.label).toList(),
            selectedValue: effectiveMode,
            onSelected: (val) => onChanged?.call(val),
            colors: colors,
            height: 38,
          ),
        ],
      ),
    );
  }
}

/// Sliding Capsule Theme Appearance Selector (System / Light / Dark)
class _ThemeSelector extends StatefulWidget {
  final String themeMode;
  final VocaColorPalette colors;
  final bool isDark;
  final ValueChanged<String>? onChanged;

  const _ThemeSelector({
    required this.themeMode,
    required this.colors,
    required this.isDark,
    this.onChanged,
  });

  @override
  State<_ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<_ThemeSelector> {
  late String _currentTheme;

  @override
  void initState() {
    super.initState();
    _currentTheme = _validTheme(widget.themeMode);
  }

  @override
  void didUpdateWidget(covariant _ThemeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode) {
      _currentTheme = _validTheme(widget.themeMode);
    }
  }

  String _validTheme(String mode) {
    return (mode == 'system' || mode == 'light' || mode == 'dark')
        ? mode
        : 'system';
  }

  void _onSelectTheme(String mode) {
    if (_currentTheme == mode) return;
    setState(() {
      _currentTheme = mode;
    });

    // Let the slider pill glide smoothly across to the new position first
    // so the animation completes without jank before the entire MaterialApp theme rebuilds
    Future.delayed(const Duration(milliseconds: 190), () {
      if (mounted) {
        widget.onChanged?.call(mode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: widget.colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.colors.borderColorLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 16, color: widget.colors.accentPrimary),
              const SizedBox(width: 6),
              Text(
                context.t('onboarding.appearance', null, 'Appearance'),
                style: TextStyle(
                  color: widget.colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Sliding Segmented Capsule Bar with Icons
          VocaSlidingSegmentedBar(
            values: const ['system', 'light', 'dark'],
            labels: [
              context.t('onboarding.themeSystem', null, 'System'),
              context.t('onboarding.themeLight', null, 'Light'),
              context.t('onboarding.themeDark', null, 'Dark'),
            ],
            icons: const [
              Icons.brightness_auto_outlined,
              Icons.light_mode_outlined,
              Icons.dark_mode_outlined,
            ],
            selectedValue: _currentTheme,
            onSelected: _onSelectTheme,
            colors: widget.colors,
            height: 38,
          ),
        ],
      ),
    );
  }
}

/// Material 3 Starter Loot Reward Cache
class _StarterLootBanner extends StatelessWidget {
  final VocaColorPalette colors;
  final bool isDark;

  const _StarterLootBanner({
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColorLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard_rounded, size: 16, color: colors.accentPrimary),
              const SizedBox(width: 6),
              Text(
                context.t('onboarding.starterBonusTitle', null, 'Starter Pack'),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LootTile(
                  icon: Icons.diamond_rounded,
                  iconColor: colors.colorDiamond,
                  text: context.t(
                    'onboarding.starterLoot.diamonds',
                    null,
                    '5 AI Captions',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LootTile(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: colors.accentSecondary,
                  text: context.t(
                    'onboarding.starterLoot.xp',
                    null,
                    '+50 Starter XP',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _LootTile(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: colors.colorFire,
                  text: context.t(
                    'onboarding.starterLoot.hearth',
                    null,
                    'Day 1 Streak',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LootTile(
                  icon: Icons.ac_unit_rounded,
                  iconColor: colors.colorDiamond,
                  text: context.t(
                    'onboarding.starterLoot.freeze',
                    null,
                    'Streak Freeze',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LootTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _LootTile({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.borderColorLight.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.22 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
