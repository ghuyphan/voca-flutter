// lib/ui/gamification/widgets/achievements_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../config/voca_theme.dart';
import '../../../services/gamification_service.dart';
import '../../../services/i18n_service.dart';
import '../../../services/toast_service.dart';
import '../../../state/app_state.dart';
import '../../sheets/voca_bottom_sheet.dart';
import '../achievements_hub_screen.dart';
import 'rpg_shield_crest.dart';

/// Modal bottom sheet presenting user RPG progression, tiers, and achievements.
/// Features a heroic centered header banner matching the session recap / complete style.
class AchievementsSheet extends StatefulWidget {
  final AchievementCategory? initialCategory;

  const AchievementsSheet({
    super.key,
    this.initialCategory,
  });

  static Future<void> show(
    BuildContext context, {
    AchievementCategory? initialCategory,
  }) {
    return showVocaBottomSheet(
      context: context,
      showCloseButton: true,
      maxHeightFactor: 0.90,
      contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      builder: (_) => AchievementsSheet(initialCategory: initialCategory),
    );
  }

  @override
  State<AchievementsSheet> createState() => _AchievementsSheetState();
}

class _AchievementsSheetState extends State<AchievementsSheet> {
  AchievementCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final gamification = AppState.instance.gamificationService;

    return Watch((context) {
      final userLvl = gamification.level.value;
      final totalXp = gamification.xp.value;
      final levelProgress = gamification.levelProgress.value;
      final progressToNextPercent = gamification.progressToNextPercent.value;
      final crestTier = GamificationService.getRankTier(userLvl);
      final allAchievements = gamification.achievements.value;

      final unlockedCount = allAchievements.where((a) => a.isUnlocked).length;
      final totalCount = allAchievements.length;

      final filtered = _selectedCategory == null
          ? allAchievements
          : allAchievements.where((a) => a.category == _selectedCategory).toList();

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),

            // 1. Centered Hero Shield Crest (Matching Session Recap style)
            Center(
              child: RpgShieldCrest(
                width: 76,
                height: 86,
                style: crestTier,
                icon: Icons.emoji_events_rounded,
                iconSize: 38,
                showGlow: true,
              ),
            ),
            const SizedBox(height: 14),

            // 2. Rank Pill Badge (e.g. [ ★ Cấp độ 12 · Chiến binh Vàng ])
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: crestTier.glowColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: crestTier.glowColor.withValues(alpha: 0.35), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: crestTier.glowColor),
                    const SizedBox(width: 5),
                    Text(
                      '${context.t('gamification.level', null, 'Level')} $userLvl · ${crestTier.displayName}',
                      style: TextStyle(
                        color: crestTier.glowColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Centered Large Bold Title
            Text(
              context.t('achievements.title', null, 'Achievements & Levels'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),

            // 4. Centered Subtitle
            Text(
              context.t('gamification.hubSubtitle', null, 'Explore badges & level up your mastery'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),

            // 5. XP Progress Card Dock
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.borderColorLight),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$totalXp XP · $progressToNextPercent% ${context.t('gamification.toLevel', null, 'to Level')} ${userLvl < 50 ? userLvl + 1 : 'MAX'}',
                        style: TextStyle(color: colors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$unlockedCount/$totalCount ${context.t('achievements.unlocked', null, 'unlocked')}',
                        style: TextStyle(color: colors.accentTertiary, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: levelProgress,
                      minHeight: 5,
                      backgroundColor: colors.bgCard,
                      valueColor: AlwaysStoppedAnimation<Color>(crestTier.rimGradient.colors.first),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6. Category Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildCategoryFilterChip(
                    colors: colors,
                    label: context.t('achievements.catAll', null, 'All'),
                    count: '$unlockedCount/$totalCount',
                    isSelected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  ...AchievementCategory.values.map((cat) {
                    final inCat = allAchievements.where((a) => a.category == cat).toList();
                    final unlInCat = inCat.where((a) => a.isUnlocked).length;
                    return _buildCategoryFilterChip(
                      colors: colors,
                      label: _categoryLabel(context, cat),
                      count: '$unlInCat/${inCat.length}',
                      isSelected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 7. Achievement Cards List
            ...filtered.map((a) => _buildAchievementCard(
                  context: context,
                  colors: colors,
                  achievement: a,
                  onClaim: () {
                    HapticFeedback.mediumImpact();
                    final ok = gamification.claimAchievement(a.id);
                    if (ok) {
                      ToastService.success(
                        context,
                        '${context.t('missions.claimed', null, 'Claimed')} +${a.xpReward} XP!',
                      );
                    }
                  },
                )),

            const SizedBox(height: 12),

            // 8. Adventurer's Hall / Leaderboard Link
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AchievementsHubScreen(initialTabIndex: 2),
                    ),
                  );
                },
                icon: Icon(Icons.leaderboard_rounded, size: 16, color: colors.colorFire),
                label: Text(
                  context.t('leaderboard.tabTitle', null, 'View World Leaderboard →'),
                  style: TextStyle(
                    color: colors.colorFire,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _categoryLabel(BuildContext context, AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.immersion:
        return context.t('achievements.catImmersion', null, 'Immersion');
      case AchievementCategory.vocabulary:
        return context.t('achievements.catVocab', null, 'Vocabulary');
      case AchievementCategory.streak:
        return context.t('achievements.catStreak', null, 'Streak');
      case AchievementCategory.srs:
        return context.t('achievements.catSrs', null, 'SRS Deck');
      case AchievementCategory.quiz:
        return context.t('achievements.catQuiz', null, 'Practice');
    }
  }

  Widget _buildCategoryFilterChip({
    required VocaColorPalette colors,
    required String label,
    required String count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary : colors.bgSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? colors.accentPrimary : colors.borderColorLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : colors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard({
    required BuildContext context,
    required VocaColorPalette colors,
    required Achievement achievement,
    required VoidCallback onClaim,
  }) {
    RpgCrestStyle crestStyleForTier(AchievementTier tier) {
      switch (tier) {
        case AchievementTier.bronze:
          return RpgCrestStyle.bronze;
        case AchievementTier.silver:
          return RpgCrestStyle.silver;
        case AchievementTier.gold:
          return RpgCrestStyle.gold;
        case AchievementTier.diamond:
          return RpgCrestStyle.diamond;
      }
    }

    final crestStyle = crestStyleForTier(achievement.tier);
    final canClaim = achievement.canClaim;
    final isUnlocked = achievement.isUnlocked;
    final title = achievement.localizedTitle(context);
    final desc = achievement.localizedDescription(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canClaim
              ? colors.accentTertiary.withValues(alpha: 0.6)
              : (isUnlocked
                  ? colors.accentTertiary.withValues(alpha: 0.25)
                  : colors.borderColor),
          width: canClaim ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Crest Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Opacity(
                opacity: isUnlocked ? 1.0 : 0.40,
                child: RpgShieldCrest(
                  width: 42,
                  height: 48,
                  style: crestStyle,
                  icon: achievement.icon,
                  iconSize: 20,
                  showGlow: isUnlocked,
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isUnlocked ? colors.colorGrammar : colors.bgSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.bgCard, width: 1.5),
                  ),
                  child: Center(
                    child: Icon(
                      isUnlocked ? Icons.check : Icons.lock_outline_rounded,
                      size: 9,
                      color: isUnlocked ? Colors.white : colors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Tier + XP
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isUnlocked ? colors.textPrimary : colors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: crestStyle.rimGradient.colors.first.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              achievement.tier.name.toUpperCase(),
                              style: TextStyle(
                                color: crestStyle.rimGradient.colors.first,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: colors.accentTertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${achievement.xpReward} XP',
                        style: TextStyle(
                          color: colors.accentTertiary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Description
                Text(
                  desc,
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 8),

                // Progress Indicator + Action
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: achievement.progress,
                          minHeight: 4.5,
                          backgroundColor: colors.bgSecondary,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isUnlocked ? colors.accentTertiary : colors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (canClaim)
                      FilledButton.tonal(
                        onPressed: onClaim,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.accentTertiary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text(
                          context.t('missions.claim', null, 'Claim'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      )
                    else if (achievement.isClaimed)
                      Text(
                        context.t('missions.claimed', null, 'Claimed'),
                        style: TextStyle(
                          color: colors.colorGrammar,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      Text(
                        '${achievement.current}/${achievement.target}',
                        style: TextStyle(
                          color: isUnlocked ? colors.accentTertiary : colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
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
