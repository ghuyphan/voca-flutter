// lib/ui/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../services/gamification_service.dart';
import '../../state/app_state.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSigningIn = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isSigningIn = true);
    try {
      await AppState.instance.supabaseService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out? Your offline progress will remain saved on this device.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AppState.instance.supabaseService.signOut();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = AppState.instance.supabaseService;
    final currentUser = supabase.currentUser;
    final gamification = AppState.instance.gamificationService;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'Learner Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: 'Settings',
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
          color: const Color(0xFF6366F1),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. User Header & Auth Card
                _buildUserCard(currentUser),

                const SizedBox(height: 16),

                // 2. XP & Level Progress Card
                _buildXpCard(gamification),

                const SizedBox(height: 16),

                // 3. Streak Stat & 7-Day Activity Calendar Card
                _buildStreakCard(gamification),

                const SizedBox(height: 16),

                // 4. Diamonds / AI Credits Card
                _buildDiamondsCard(gamification),

                const SizedBox(height: 24),

                // 5. Pre-defined Achievements Section
                _buildAchievementsSection(gamification),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(dynamic currentUser) {
    final isAuthenticated = currentUser != null;
    final email = isAuthenticated ? (currentUser.email ?? 'Learner') : 'Guest Learner';
    final avatarUrl = isAuthenticated ? (currentUser.userMetadata?['avatar_url'] as String?) : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF6366F1),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? const Icon(Icons.person_rounded, size: 34, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white,
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
                        color: isAuthenticated ? const Color(0xFF10B981) : Colors.amberAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAuthenticated ? 'Cloud Synced' : 'Guest Mode (Local Only)',
                      style: TextStyle(
                        color: isAuthenticated ? const Color(0xFF10B981) : Colors.amberAccent,
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
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Sign Out', style: TextStyle(fontSize: 12)),
            )
          else
            ElevatedButton.icon(
              onPressed: _isSigningIn ? null : _handleGoogleSignIn,
              icon: _isSigningIn
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.login_rounded, size: 14),
              label: const Text('Sign in', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildXpCard(GamificationService gamification) {
    return Watch((context) {
      final totalXp = gamification.xp.value;
      final level = gamification.level.value;
      final curXp = gamification.currentLevelXp.value;
      final targetXp = gamification.nextLevelTargetXp.value;
      final progress = gamification.levelProgress.value;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'LEVEL $level',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Polyglot Scholar',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  '$totalXp Total XP',
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFF0F172A),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$curXp / $targetXp XP',
                  style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                ),
                Text(
                  '${targetXp - curXp} XP to Level ${level + 1}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11.5),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStreakCard(GamificationService gamification) {
    return Watch((context) {
      final currentStreak = gamification.currentStreak.value;
      final longestStreak = gamification.longestStreak.value;
      final streakFreezes = gamification.streakFreezes.value;
      final days = gamification.activityCalendar.value;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
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
                    const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316), size: 26),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$currentStreak Day Streak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Personal Best: $longestStreak days',
                          style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.ac_unit_rounded, color: Color(0xFF38BDF8), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$streakFreezes Freezes',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 14),

            // Last 7 Days Activity Calendar
            const Text(
              'Activity (Last 7 Days)',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
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
                        color: day.isToday ? const Color(0xFF38BDF8) : Colors.white60,
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
                            ? const Color(0xFFF97316)
                            : (day.isToday ? const Color(0xFF334155) : const Color(0xFF0F172A)),
                        border: Border.all(
                          color: day.isToday
                              ? const Color(0xFF38BDF8)
                              : (day.isActive ? const Color(0xFFEA580C) : Colors.white10),
                          width: day.isToday ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: day.isActive
                            ? const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 18)
                            : Text(
                                day.dayNumber,
                                style: TextStyle(
                                  color: day.isToday ? Colors.white : Colors.white38,
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

  Widget _buildDiamondsCard(GamificationService gamification) {
    return Watch((context) {
      final diamonds = gamification.diamonds.value;
      final maxDiamonds = gamification.maxDiamonds.value;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.diamond_rounded, color: Color(0xFF38BDF8), size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$diamonds / $maxDiamonds Diamonds',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'AI Transcription & Whisper credits',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8)),
              tooltip: 'Refresh Diamonds',
              onPressed: () async {
                await gamification.refreshDiamonds();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Diamonds refreshed')),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAchievementsSection(GamificationService gamification) {
    return Watch((context) {
      final list = gamification.achievements.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACHIEVEMENTS',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                '${list.where((a) => a.isUnlocked).length} / ${list.length} Unlocked',
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
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
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUnlocked ? const Color(0xFF10B981).withOpacity(0.4) : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? const Color(0xFF10B981).withOpacity(0.2)
                          : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isUnlocked ? const Color(0xFF10B981) : Colors.white12,
                      ),
                    ),
                    child: Icon(
                      ach.icon,
                      color: isUnlocked ? const Color(0xFF10B981) : Colors.white30,
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
                                ach.title,
                                style: TextStyle(
                                  color: isUnlocked ? Colors.white : Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+${ach.xpReward} XP',
                                style: const TextStyle(
                                  color: Color(0xFF818CF8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ach.description,
                          style: const TextStyle(color: Colors.white60, fontSize: 11.5),
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
                                  backgroundColor: const Color(0xFF0F172A),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isUnlocked ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isUnlocked ? 'Completed' : '${ach.current}/${ach.target}',
                              style: TextStyle(
                                color: isUnlocked ? const Color(0xFF10B981) : Colors.white38,
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
