// lib/ui/gamification/achievements_hub_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/gamification_service.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../widgets/voca_back_button.dart';
import 'widgets/rpg_shield_crest.dart';

/// Dedicated Full-Screen Hub for Daily Missions, RPG Achievements, and Global Leaderboard.
class AchievementsHubScreen extends StatefulWidget {
  final int initialTabIndex;

  const AchievementsHubScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<AchievementsHubScreen> createState() => _AchievementsHubScreenState();
}

class _AchievementsHubScreenState extends State<AchievementsHubScreen> {
  late int _currentTab;
  AchievementCategory? _selectedCategory; // null = all
  String _leaderboardPeriod = 'weekly'; // 'weekly' or 'all_time'

  Timer? _countdownTimer;
  Duration _timeUntilMidnight = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTabIndex;
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (mounted) {
      setState(() {
        _timeUntilMidnight = tomorrow.difference(now);
      });
    }
  }

  String _formatCountdown(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final gamification = AppState.instance.gamificationService;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 68,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: VocaBackButton(),
          ),
        ),
        centerTitle: true,
        title: Text(
          context.t('gamification.hubTitle', null, "Adventurer's Hall"),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top 3-Way Segmented Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildTopSegmentedBar(colors, gamification),
            ),

            // Tab View Body
            Expanded(
              child: Watch((context) {
                switch (_currentTab) {
                  case 0:
                    return _buildMissionsTab(context, colors, gamification);
                  case 1:
                    return _buildAchievementsTab(context, colors, gamification);
                  case 2:
                  default:
                    return _buildLeaderboardTab(context, colors, gamification);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Top 3-Way Segmented Navigation Bar
  Widget _buildTopSegmentedBar(VocaColorPalette colors, GamificationService gamification) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          _buildSegmentButton(
            colors: colors,
            index: 0,
            icon: Icons.assignment_outlined,
            label: context.t('missions.tabTitle', null, 'Missions'),
            badgeCount: gamification.dailyMissions.value.missions
                    .where((m) => m.isCompleted && !m.isClaimed)
                    .length +
                (gamification.canClaimDailyBonus.value ? 1 : 0),
          ),
          _buildSegmentButton(
            colors: colors,
            index: 1,
            icon: Icons.military_tech_outlined,
            label: context.t('gamification.achievements', null, 'Achievements'),
            badgeCount: gamification.achievements.value.where((a) => a.canClaim).length,
          ),
          _buildSegmentButton(
            colors: colors,
            index: 2,
            icon: Icons.leaderboard_outlined,
            label: context.t('leaderboard.tabTitle', null, 'Leaderboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required VocaColorPalette colors,
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = _currentTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? colors.bgCard : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(colors.isDark ? 0.3 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? colors.accentPrimary : colors.textMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? colors.textPrimary : colors.textMuted,
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: colors.accentPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: DAILY MISSIONS
  // =========================================================================

  Widget _buildMissionsTab(
    BuildContext context,
    VocaColorPalette colors,
    GamificationService gamification,
  ) {
    final missionsState = gamification.dailyMissions.value;
    final missions = missionsState.missions;
    final userLvl = gamification.level.value;
    final totalXp = gamification.xp.value;
    final weeklyXp = gamification.weeklyXp.value;
    final canClaimChest = gamification.canClaimDailyBonus.value;
    final chestClaimed = missionsState.allCompletedBonusClaimed;
    final completedCount = gamification.completedMissionsCount.value;
    final totalMissions = gamification.totalMissionsCount.value;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // 1. Missions Hero Banner
          _buildHeroRankCard(
            colors: colors,
            level: userLvl,
            totalXp: totalXp,
            weeklyXp: weeklyXp,
            style: RpgCrestStyle.quest,
            centerIcon: Icons.auto_stories_rounded,
          ),
          const SizedBox(height: 14),

          // 2. Countdown Timer Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_top_rounded, size: 16, color: colors.accentTertiary),
                const SizedBox(width: 8),
                Text(
                  '${context.t('missions.resetsIn', null, 'New missions in')} ',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                Text(
                  _formatCountdown(_timeUntilMidnight),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Completion Bonus Chest Card (+50 XP)
          _buildDailyBonusChestCard(
            context: context,
            colors: colors,
            completedCount: completedCount,
            totalMissions: totalMissions,
            canClaim: canClaimChest,
            isClaimed: chestClaimed,
            bonusXp: missionsState.bonusXp,
            onClaim: () {
              final ok = gamification.claimDailyBonus();
              if (ok) {
                ToastService.success(context, 'Claimed +${missionsState.bonusXp} XP bonus chest! 🎉');
              }
            },
          ),
          const SizedBox(height: 20),

          // 4. Mission Cards
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.t('missions.todaysQuests', null, "Today's Quests"),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),

          ...missions.map((m) => _buildMissionCard(
                context: context,
                colors: colors,
                mission: m,
                onClaim: () {
                  final ok = gamification.claimMission(m.id);
                  if (ok) {
                    ToastService.success(context, 'Claimed +${m.xpReward} XP for "${m.title}"!');
                  }
                },
              )),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDailyBonusChestCard({
    required BuildContext context,
    required VocaColorPalette colors,
    required int completedCount,
    required int totalMissions,
    required bool canClaim,
    required bool isClaimed,
    required int bonusXp,
    required VoidCallback onClaim,
  }) {
    final progressRatio = totalMissions > 0 ? (completedCount / totalMissions).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: canClaim
            ? colors.accentTertiary.withOpacity(0.08)
            : colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canClaim
              ? colors.accentTertiary.withOpacity(0.5)
              : colors.borderColor,
          width: canClaim ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isClaimed
                      ? colors.success.withOpacity(0.12)
                      : (canClaim
                          ? colors.accentTertiary.withOpacity(0.2)
                          : colors.bgSecondary),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isClaimed
                        ? colors.success.withOpacity(0.3)
                        : (canClaim ? colors.accentTertiary : colors.borderColor),
                  ),
                ),
                child: Icon(
                  isClaimed ? Icons.check_circle_rounded : Icons.inventory_2_rounded,
                  color: isClaimed
                      ? colors.success
                      : (canClaim ? colors.accentTertiary : colors.textMuted),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.t('missions.dailyChest', null, 'Daily Completion Chest'),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.accentTertiary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+$bonusXp XP',
                            style: TextStyle(
                              color: colors.accentTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.t('missions.dailyChestDesc', null, 'Complete all 3 missions to unlock'),
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Claim Button
              if (isClaimed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 14, color: colors.success),
                      const SizedBox(width: 4),
                      Text(
                        context.t('missions.claimed', null, 'Claimed'),
                        style: TextStyle(color: colors.success, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else if (canClaim)
                ElevatedButton.icon(
                  onPressed: onClaim,
                  icon: const Icon(Icons.card_giftcard_rounded, size: 14),
                  label: Text(context.t('missions.claim', null, 'Claim')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentTertiary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              else
                Text(
                  '$completedCount/$totalMissions',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 6,
              backgroundColor: colors.bgSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(
                isClaimed ? colors.success : colors.accentTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard({
    required BuildContext context,
    required VocaColorPalette colors,
    required DailyMission mission,
    required VoidCallback onClaim,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: mission.isCompleted && !mission.isClaimed
              ? colors.accentPrimary.withOpacity(0.4)
              : colors.borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: mission.isCompleted
                  ? colors.success.withOpacity(0.12)
                  : colors.bgSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              mission.icon,
              size: 22,
              color: mission.isCompleted ? colors.success : colors.accentPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mission.title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '+${mission.xpReward} XP',
                      style: TextStyle(
                        color: colors.accentTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  mission.description,
                  style: TextStyle(color: colors.textMuted, fontSize: 11.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: mission.progressRatio,
                          minHeight: 5,
                          backgroundColor: colors.bgSecondary,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            mission.isCompleted ? colors.success : colors.accentPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (mission.isClaimed)
                      Text(
                        context.t('missions.claimed', null, 'Claimed'),
                        style: TextStyle(color: colors.success, fontSize: 11.5, fontWeight: FontWeight.bold),
                      )
                    else if (mission.isCompleted)
                      ElevatedButton(
                        onPressed: onClaim,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accentPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text(
                          context.t('missions.claim', null, 'Claim'),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      Text(
                        '${mission.progress}/${mission.target}',
                        style: TextStyle(color: colors.textMuted, fontSize: 11.5, fontWeight: FontWeight.bold),
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

  // =========================================================================
  // TAB 2: ACHIEVEMENTS
  // =========================================================================

  Widget _buildAchievementsTab(
    BuildContext context,
    VocaColorPalette colors,
    GamificationService gamification,
  ) {
    final userLvl = gamification.level.value;
    final totalXp = gamification.xp.value;
    final weeklyXp = gamification.weeklyXp.value;
    final levelProgress = gamification.levelProgress.value;
    final progressToNextPercent = gamification.progressToNextPercent.value;
    final crestTier = GamificationService.getRankTier(userLvl);
    final allAchievements = gamification.achievements.value;

    final unlockedCount = allAchievements.where((a) => a.isUnlocked).length;
    final totalCount = allAchievements.length;

    // Filter achievements
    final filtered = _selectedCategory == null
        ? allAchievements
        : allAchievements.where((a) => a.category == _selectedCategory).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // 1. Level Hero Card
          _buildHeroRankCard(
            colors: colors,
            level: userLvl,
            totalXp: totalXp,
            weeklyXp: weeklyXp,
            style: crestTier,
            centerIcon: Icons.military_tech_rounded,
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$progressToNextPercent% to Level ${userLvl < 50 ? userLvl + 1 : 'MAX'}',
                      style: TextStyle(color: colors.textMuted, fontSize: 11.5),
                    ),
                    Text(
                      '$unlockedCount/$totalCount Unlocked',
                      style: TextStyle(color: colors.accentTertiary, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: levelProgress,
                    minHeight: 6,
                    backgroundColor: colors.bgSecondary,
                    valueColor: AlwaysStoppedAnimation<Color>(crestTier.rimGradient.colors.first),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildCategoryFilterChip(
                  colors: colors,
                  label: context.t('common.all', null, 'All'),
                  count: '$unlockedCount/$totalCount',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...AchievementCategory.values.map((cat) {
                  final inCat = allAchievements.where((a) => a.category == cat).toList();
                  final unlInCat = inCat.where((a) => a.isUnlocked).length;
                  return _buildCategoryFilterChip(
                    colors: colors,
                    label: _categoryLabel(cat),
                    count: '$unlInCat/${inCat.length}',
                    isSelected: _selectedCategory == cat,
                    onTap: () => setState(() => _selectedCategory = cat),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Badges List
          ...filtered.map((a) => _buildAchievementCard(
                context: context,
                colors: colors,
                achievement: a,
                onClaim: () {
                  final ok = gamification.claimAchievement(a.id);
                  if (ok) {
                    ToastService.success(context, 'Claimed +${a.xpReward} XP for "${a.title}"!');
                  }
                },
              )),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _categoryLabel(AchievementCategory cat) {
    switch (cat) {
      case AchievementCategory.immersion:
        return 'Immersion';
      case AchievementCategory.vocabulary:
        return 'Vocabulary';
      case AchievementCategory.streak:
        return 'Streak';
      case AchievementCategory.srs:
        return 'Memory';
      case AchievementCategory.quiz:
        return 'Quiz';
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
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary : colors.bgSecondary,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? colors.accentPrimary : colors.borderColor,
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
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : colors.bgHover,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: achievement.canClaim
              ? colors.accentTertiary.withOpacity(0.6)
              : (achievement.isUnlocked
                  ? colors.accentTertiary.withOpacity(0.25)
                  : colors.borderColor),
          width: achievement.canClaim ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Crest Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Opacity(
                opacity: achievement.isUnlocked ? 1.0 : 0.45,
                child: RpgShieldCrest(
                  width: 44,
                  height: 50,
                  style: crestStyle,
                  icon: achievement.icon,
                  iconSize: 22,
                  showGlow: achievement.isUnlocked,
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: achievement.isUnlocked ? colors.success : colors.bgHover,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.bgCard, width: 1.5),
                  ),
                  child: Center(
                    child: Icon(
                      achievement.isUnlocked ? Icons.check : Icons.lock_outline_rounded,
                      size: 9,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              achievement.title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: achievement.isUnlocked ? colors.textPrimary : colors.textMuted,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: crestStyle.rimGradient.colors.first.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              achievement.tier.name.toUpperCase(),
                              style: TextStyle(
                                color: crestStyle.rimGradient.colors.first,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${achievement.xpReward} XP',
                      style: TextStyle(
                        color: achievement.isUnlocked ? colors.accentTertiary : colors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  achievement.description,
                  style: TextStyle(color: colors.textMuted, fontSize: 11.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: achievement.progress,
                          minHeight: 5,
                          backgroundColor: colors.bgSecondary,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            achievement.isUnlocked ? colors.accentTertiary : colors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (achievement.canClaim)
                      ElevatedButton(
                        onPressed: onClaim,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accentTertiary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('Claim', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    else
                      Text(
                        '${achievement.current}/${achievement.target}',
                        style: TextStyle(
                          color: achievement.isUnlocked ? colors.accentTertiary : colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
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

  // =========================================================================
  // TAB 3: LEADERBOARD
  // =========================================================================

  Widget _buildLeaderboardTab(
    BuildContext context,
    VocaColorPalette colors,
    GamificationService gamification,
  ) {
    final learners = gamification.getLeaderboardEntries(period: _leaderboardPeriod);
    final top3 = learners.take(3).toList();
    final remaining = learners.skip(3).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Period Toggle ("This Week" / "All Time")
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 36,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colors.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Row(
                  children: [
                    _buildPeriodPill(colors, 'weekly', context.t('leaderboard.thisWeek', null, 'This Week')),
                    _buildPeriodPill(colors, 'all_time', context.t('leaderboard.allTime', null, 'All Time')),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh_rounded, size: 20, color: colors.textMuted),
                onPressed: () {
                  ToastService.info(context, 'Leaderboard synced with Adventurer Guild.');
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Top 3 Adventurer's Podium
          if (top3.length >= 3)
            _buildPodium(colors, top3[0], top3[1], top3[2]),
          const SizedBox(height: 24),

          // Ranks 4+ List
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.t('leaderboard.guildRankings', null, 'Guild Rankings'),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),

          ...remaining.map((entry) => _buildLeaderboardRow(colors, entry)),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPeriodPill(VocaColorPalette colors, String id, String label) {
    final isSelected = _leaderboardPeriod == id;
    return GestureDetector(
      onTap: () => setState(() => _leaderboardPeriod = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.bgCard : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colors.textPrimary : colors.textMuted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(
    VocaColorPalette colors,
    LeaderboardEntry first,
    LeaderboardEntry second,
    LeaderboardEntry third,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // #2 Silver
        Expanded(child: _buildPodiumPlinth(colors, second, rank: 2, height: 110, style: RpgCrestStyle.silver)),
        const SizedBox(width: 8),
        // #1 Gold (Taller)
        Expanded(child: _buildPodiumPlinth(colors, first, rank: 1, height: 135, style: RpgCrestStyle.gold)),
        const SizedBox(width: 8),
        // #3 Bronze
        Expanded(child: _buildPodiumPlinth(colors, third, rank: 3, height: 95, style: RpgCrestStyle.bronze)),
      ],
    );
  }

  Widget _buildPodiumPlinth(
    VocaColorPalette colors,
    LeaderboardEntry entry, {
    required int rank,
    required double height,
    required RpgCrestStyle style,
  }) {
    final score = _leaderboardPeriod == 'weekly' ? entry.weeklyXp : entry.xp;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with crown/crest
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: rank == 1 ? 52 : 44,
              height: rank == 1 ? 52 : 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: style.rimGradient.colors.first, width: 2),
                color: colors.bgSecondary,
                image: entry.avatar.isNotEmpty
                    ? DecorationImage(image: NetworkImage(entry.avatar), fit: BoxFit.cover)
                    : null,
              ),
              child: entry.avatar.isEmpty
                  ? Center(
                      child: Text(
                        entry.name.substring(0, 1),
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    )
                  : null,
            ),
            Positioned(
              top: -10,
              child: Icon(
                rank == 1 ? Icons.emoji_events_rounded : Icons.shield_rounded,
                size: rank == 1 ? 18 : 14,
                color: style.rimGradient.colors.first,
              ),
            ),
            Positioned(
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: style.rimGradient.colors.first,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(color: Colors.black, fontSize: 9.5, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Name
        Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: entry.isCurrentUser ? colors.accentPrimary : colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Lv.${entry.level}',
          style: TextStyle(color: colors.textMuted, fontSize: 10.5),
        ),
        const SizedBox(height: 8),

        // Stone Plinth Pillar
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                style.rimGradient.colors.first.withOpacity(0.25),
                colors.bgSecondary,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: style.rimGradient.colors.first.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: rank == 1 ? 16 : 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'XP',
                style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardRow(VocaColorPalette colors, LeaderboardEntry entry) {
    final score = _leaderboardPeriod == 'weekly' ? entry.weeklyXp : entry.xp;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: entry.isCurrentUser ? colors.accentPrimary.withOpacity(0.08) : colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isCurrentUser ? colors.accentPrimary.withOpacity(0.4) : colors.borderColor,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                color: entry.isCurrentUser ? colors.accentPrimary : colors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.bgSecondary,
              image: entry.avatar.isNotEmpty
                  ? DecorationImage(image: NetworkImage(entry.avatar), fit: BoxFit.cover)
                  : null,
            ),
            child: entry.avatar.isEmpty
                ? Center(
                    child: Text(
                      entry.name.substring(0, 1),
                      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isCurrentUser ? '${entry.name} (You)' : entry.name,
                  style: TextStyle(
                    color: entry.isCurrentUser ? colors.accentPrimary : colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Lv.${entry.level} • 🔥 ${entry.streak}d streak',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '$score XP',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SHARED HERO CARD
  // =========================================================================

  Widget _buildHeroRankCard({
    required VocaColorPalette colors,
    required int level,
    required int totalXp,
    required int weeklyXp,
    required RpgCrestStyle style,
    required IconData centerIcon,
    Widget? footer,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              RpgShieldCrest(
                width: 60,
                height: 68,
                style: style,
                icon: centerIcon,
                iconSize: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: style.rimGradient.colors.first.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: style.rimGradient.colors.first.withOpacity(0.3)),
                      ),
                      child: Text(
                        'LEVEL $level • ${style.displayName.toUpperCase()}',
                        style: TextStyle(
                          color: style.rimGradient.colors.first,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      GamificationService.getRankTitle(level),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalXp Total XP • ⚡ $weeklyXp this week',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (footer != null) footer,
        ],
      ),
    );
  }
}
