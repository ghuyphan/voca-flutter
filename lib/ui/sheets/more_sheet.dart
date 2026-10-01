// lib/ui/sheets/more_sheet.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../state/app_state.dart';
import '../library/library_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import 'gamification_dialogs.dart';

/// Authentic More Bottom Sheet matching lingua-tube.
class MoreSheet extends StatelessWidget {
  final VoidCallback? onOpenPlaylists;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenProfile;

  const MoreSheet({
    super.key,
    this.onOpenPlaylists,
    this.onOpenHistory,
    this.onOpenSettings,
    this.onOpenProfile,
  });

  /// Displays the MoreSheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onOpenPlaylists,
    VoidCallback? onOpenHistory,
    VoidCallback? onOpenSettings,
    VoidCallback? onOpenProfile,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MoreSheet(
        onOpenPlaylists: onOpenPlaylists,
        onOpenHistory: onOpenHistory,
        onOpenSettings: onOpenSettings,
        onOpenProfile: onOpenProfile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gamification = AppState.instance.gamificationService;

    return Container(
      decoration: const BoxDecoration(
        color: VocaTokens.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: VocaTokens.borderColor),
          left: BorderSide(color: VocaTokens.borderColor),
          right: BorderSide(color: VocaTokens.borderColor),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VocaTokens.borderColorHover,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              const Text(
                'More',
                style: TextStyle(
                  color: VocaTokens.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),

              // Top Quick Bar: 3 Interactive Stat Cards
              Watch((context) {
                final streak = gamification.currentStreak.value;
                final level = gamification.level.value;
                final diamonds = gamification.diamonds.value;
                final maxDiamonds = gamification.maxDiamonds.value;

                return Row(
                  children: [
                    // 1. Streak Card
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: '🔥',
                        iconColor: VocaTokens.colorFire,
                        value: '$streak',
                        label: 'Day Streak',
                        onTap: () => showStreakDialog(context),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 2. Level Card
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: '🛡️',
                        iconColor: VocaTokens.accentTertiary,
                        value: '$level',
                        label: 'Level',
                        onTap: () => showAchievementsDialog(context),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 3. AI Credits Card
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: '💎',
                        iconColor: VocaTokens.colorDiamond,
                        value: '$diamonds/$maxDiamonds',
                        label: 'AI Credits',
                        onTap: () => showAiCreditsDialog(context),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 16),
              const Divider(color: VocaTokens.borderColor, height: 1),
              const SizedBox(height: 8),

              // Action Rows
              _buildActionRow(
                context: context,
                icon: Icons.playlist_play_rounded,
                iconColor: const Color(0xFF38BDF8),
                title: 'Playlists',
                onTap: () {
                  Navigator.of(context).pop();
                  if (onOpenPlaylists != null) {
                    onOpenPlaylists!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LibraryScreen(initialTabIndex: 1),
                      ),
                    );
                  }
                },
              ),
              _buildActionRow(
                context: context,
                icon: Icons.history_rounded,
                iconColor: const Color(0xFFA78BFA),
                title: 'History',
                onTap: () {
                  Navigator.of(context).pop();
                  if (onOpenHistory != null) {
                    onOpenHistory!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LibraryScreen(initialTabIndex: 0),
                      ),
                    );
                  }
                },
              ),
              _buildActionRow(
                context: context,
                icon: Icons.settings_outlined,
                iconColor: VocaTokens.textSecondary,
                title: 'Settings',
                onTap: () {
                  Navigator.of(context).pop();
                  if (onOpenSettings != null) {
                    onOpenSettings!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  }
                },
              ),
              _buildActionRow(
                context: context,
                icon: Icons.person_outline_rounded,
                iconColor: VocaTokens.accentPrimary,
                title: 'Account & Profile',
                onTap: () {
                  Navigator.of(context).pop();
                  if (onOpenProfile != null) {
                    onOpenProfile!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String icon,
    required Color iconColor,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: VocaTokens.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: VocaTokens.borderColor),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  color: VocaTokens.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: VocaTokens.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: VocaTokens.bgSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: VocaTokens.borderColorLight),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: VocaTokens.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: VocaTokens.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
