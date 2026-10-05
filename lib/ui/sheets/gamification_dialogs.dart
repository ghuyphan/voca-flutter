// lib/ui/sheets/gamification_dialogs.dart

import 'package:flutter/material.dart';
import '../gamification/streak_screen.dart';
import '../gamification/achievements_hub_screen.dart';
import '../gamification/ai_credits_screen.dart';

/// Opens dedicated Streak Screen full experience.
Future<void> showStreakDialog(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => const StreakScreen(),
    ),
  );
}

/// Opens dedicated Achievements Hub Screen (focusing on Achievements tab).
Future<void> showAchievementsDialog(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => const AchievementsHubScreen(initialTabIndex: 1),
    ),
  );
}

/// Opens dedicated Daily Missions Hub Screen (focusing on Missions tab).
Future<void> showMissionsDialog(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => const AchievementsHubScreen(initialTabIndex: 0),
    ),
  );
}

/// Opens dedicated Global Leaderboard Screen (focusing on Leaderboard tab).
Future<void> showLeaderboardDialog(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => const AchievementsHubScreen(initialTabIndex: 2),
    ),
  );
}

/// Opens dedicated AI Credits Screen full experience.
Future<void> showAiCreditsDialog(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => const AiCreditsScreen(initialShowCheckout: false),
    ),
  );
}

/// Opens dedicated Pro & Founder Upgrade screen with VietQR checkout visible.
Future<void> showProUpgradeDialog(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => const AiCreditsScreen(initialShowCheckout: true),
    ),
  );
}
