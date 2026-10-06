// lib/ui/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/gamification_service.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../auth/auth_screen.dart';
import '../settings/settings_screen.dart';
import '../widgets/voca_back_button.dart';
import '../widgets/voca_confirm_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _handleSignIn() async {
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    if (res == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showVocaConfirmDialog(
      context: context,
      title: context.t('profile.signOut', null, 'Sign Out'),
      message: context.t('profile.signOutConfirm', null, 'Are you sure you want to sign out? Your offline progress will remain saved on this device.'),
      confirmText: context.t('profile.signOut', null, 'Sign Out'),
      variant: ConfirmDialogVariant.danger,
    );

    if (confirmed == true) {
      await AppState.instance.authService.signOut();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final supabase = AppState.instance.supabaseService;
    final currentUser = supabase.currentUser;
    final gamification = AppState.instance.gamificationService;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        elevation: 0,
        leadingWidth: 68,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: VocaBackButton(
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
        titleSpacing: 8,
        title: Text(
          context.t('profile.title', null, 'Learner Profile'),
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colors.textSecondary),
            tooltip: context.t('nav.settings', null, 'Settings'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await gamification.refreshDiamonds();
            if (mounted) setState(() {});
          },
          color: colors.accentPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. User Header & Auth Card
                _buildUserCard(colors, currentUser),

                const SizedBox(height: 16),

                // 2. XP & Level Progress Card
                _buildXpCard(colors, gamification),

                const SizedBox(height: 16),

                // 3. Streak Stat & 7-Day Activity Calendar Card
                _buildStreakCard(colors, gamification),

                const SizedBox(height: 16),

                // 4. Diamonds / AI Credits Card
                _buildDiamondsCard(colors, gamification),

                const SizedBox(height: 24),

                // 5. Pre-defined Achievements Section
                _buildAchievementsSection(colors, gamification),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(VocaColorPalette colors, dynamic currentUser) {
    final profile = AppState.instance.authService.userProfile.value;
    final isAuthenticated = profile != null || currentUser != null;
    final displayName = profile?.name ?? profile?.email ?? (currentUser?.email ?? context.t('profile.guestLearner', null, 'Guest Learner'));
    final avatarUrl = profile?.avatarUrl ?? (currentUser?.userMetadata?['avatar_url'] as String?);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: colors.accentPrimarySoft,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Icon(Icons.person_rounded, size: 34, color: colors.accentPrimary)
                : null,
          ),
          const SizedBox(width: 14),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAuthenticated ? colors.success : colors.warning,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAuthenticated
                          ? context.t('profile.cloudSynced', null, 'Cloud Synced')
                          : context.t('profile.guestMode', null, 'Guest Mode (Local Only)'),
                      style: TextStyle(
                        color: isAuthenticated ? colors.success : colors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sign in / Sign out button
          if (isAuthenticated)
            OutlinedButton(
              onPressed: _handleSignOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(context.t('profile.signOut', null, 'Sign Out'), style: const TextStyle(fontSize: 12)),
            )
          else
            ElevatedButton.icon(
              onPressed: _handleSignIn,
              icon: const Icon(Icons.login_rounded, size: 14),
              label: Text(context.t('profile.signIn', null, 'Sign In'), style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildXpCard(VocaColorPalette colors, GamificationService gamification) {
    return Watch((context) {
      final totalXp = gamification.xp.value;
      final level = gamification.level.value;
      final curXp = gamification.currentLevelXp.value;
      final targetXp = gamification.nextLevelTargetXp.value;
      final progress = gamification.levelProgress.value;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.accentPrimary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${context.t('gamification.level', null, 'LEVEL').toUpperCase()} $level',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('gamification.polyglotScholar', null, 'Polyglot Scholar'),
                      style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  '$totalXp ${context.t('gamification.totalXp', null, 'Total XP')}',
                  style: TextStyle(color: colors.accentTertiary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: colors.bgSecondary,
                valueColor: AlwaysStoppedAnimation<Color>(colors.accentTertiary),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$curXp / $targetXp XP',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
                ),
                Text(
                  '${targetXp - curXp} XP to Level ${level + 1}',
                  style: TextStyle(color: colors.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStreakCard(VocaColorPalette colors, GamificationService gamification) {
    return Watch((context) {
      final currentStreak = gamification.currentStreak.value;
      final longestStreak = gamification.longestStreak.value;
      final streakFreezes = gamification.streakFreezes.value;
      final days = gamification.activityCalendar.value;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded, color: colors.colorFire, size: 26),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$currentStreak ${context.t('streak.dayStreak', null, 'Day Streak')}',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${context.t('streak.personalBest', null, 'Personal Best')}: $longestStreak ${context.t('study.days', null, 'days')}',
                          style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.accentSecondarySoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.accentSecondary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.ac_unit_rounded, color: colors.accentSecondary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$streakFreezes ${context.t('streak.freezesRemaining', null, 'Freezes')}',
                        style: TextStyle(color: colors.accentSecondary, fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: colors.borderColorLight, height: 1),
            const SizedBox(height: 14),

            // Last 7 Days Activity Calendar
            Text(
              context.t('streak.activityLast7Days', null, 'Activity (Last 7 Days)'),
              style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((day) {
                return Column(
                  children: [
                    Text(
                      day.dayLabel,
                      style: TextStyle(
                        color: day.isToday ? colors.accentPrimary : colors.textMuted,
                        fontSize: 11,
                        fontWeight: day.isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: day.isActive
                            ? colors.colorFire
                            : (day.isToday ? colors.bgHover : colors.bgSecondary),
                        border: Border.all(
                          color: day.isToday
                              ? colors.accentPrimary
                              : (day.isActive ? colors.colorFire : colors.borderColor),
                          width: day.isToday ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: day.isActive
                            ? const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 18)
                            : Text(
                                day.dayNumber,
                                style: TextStyle(
                                  color: day.isToday ? colors.accentPrimary : colors.textMuted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDiamondsCard(VocaColorPalette colors, GamificationService gamification) {
    return Watch((context) {
      final diamonds = gamification.diamonds.value;
      final maxDiamonds = gamification.maxDiamonds.value;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.colorDiamond.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.diamond_rounded, color: colors.colorDiamond, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$diamonds / $maxDiamonds ${context.t('subtitle.diamonds', null, 'Diamonds')}',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.t('profile.aiCreditsDesc', null, 'AI Transcription & Whisper credits'),
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: colors.colorDiamond),
              tooltip: context.t('aiCredits.refresh', null, 'Refresh Diamonds'),
              onPressed: () async {
                final msg = context.t('aiCredits.refreshed', null, 'Diamonds refreshed');
                await gamification.refreshDiamonds();
                if (!mounted) return;
                ToastService.info(this.context, msg);
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAchievementsSection(VocaColorPalette colors, GamificationService gamification) {
    return Watch((context) {
      final list = gamification.achievements.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.t('gamification.achievements', null, 'ACHIEVEMENTS').toUpperCase(),
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                '${list.where((a) => a.isUnlocked).length} / ${list.length} ${context.t('achievements.unlocked', null, 'Unlocked')}',
                style: TextStyle(color: colors.accentTertiary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...list.map((ach) {
            final isUnlocked = ach.isUnlocked;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUnlocked ? colors.accentTertiary.withOpacity(0.4) : colors.borderColor,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? colors.accentTertiary.withOpacity(0.15)
                          : colors.bgSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isUnlocked ? colors.accentTertiary.withOpacity(0.3) : colors.borderColor,
                      ),
                    ),
                    child: Icon(
                      ach.icon,
                      color: isUnlocked ? colors.accentTertiary : colors.textMuted,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.t('achievements.${ach.id}.title', null, ach.title),
                                style: TextStyle(
                                  color: isUnlocked ? colors.textPrimary : colors.textMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.accentPrimarySoft,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+${ach.xpReward} XP',
                                style: TextStyle(
                                  color: colors.accentPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.t('achievements.${ach.id}.desc', null, ach.description),
                          style: TextStyle(color: colors.textMuted, fontSize: 11.5),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: ach.progress,
                                  minHeight: 4,
                                  backgroundColor: colors.bgSecondary,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isUnlocked ? colors.accentTertiary : colors.accentPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isUnlocked ? context.t('achievements.completed', null, 'Completed') : '${ach.current}/${ach.target}',
                              style: TextStyle(
                                color: isUnlocked ? colors.accentTertiary : colors.textMuted,
                                fontSize: 10.5,
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
          }),
        ],
      );
    });
  }
}
