// lib/ui/widgets/voca_bottom_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';

/// Material 3 NavigationBar for Voca mobile shell.
///
/// Implements Google's Material 3 NavigationBar with:
/// - 4 primary destinations: Watch, Review, Vocab, Library
/// - Themed indicators & typography from [VocaTheme.navigationBarTheme]
/// - Dynamic locale reactivity bound to [I18nService.currentLanguage]
/// - Live activity badge indicators (playing session, claimable rewards)
/// - Hairline top divider separating content from the navigation bar
class VocaBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onCreatePressed;
  final VoidCallback? onMorePressed;

  const VocaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.onCreatePressed,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Watch((context) {
      // Subscribe to language changes so labels update instantaneously
      final _ = I18nService.instance.currentLanguage.value;

      bool hasRewards = false;
      try {
        hasRewards = AppState.instance.gamificationService.hasClaimableRewards.value;
      } catch (_) {
        hasRewards = false;
      }

      final watchLabel = context.t('nav.watch', null, 'Watch');
      final reviewLabel = context.t('nav.review', null, 'Review');
      final vocabLabel = context.t('nav.vocab', null, 'Vocab');
      final libraryLabel = context.t('nav.library', null, 'Library');

      return NavigationBar(
        selectedIndex: currentIndex.clamp(0, 3),
          onDestinationSelected: (index) {
            onTabSelected(index);
            if (index == 3) {
              onMorePressed?.call();
            }
          },
          destinations: [
            // 1. Watch
            NavigationDestination(
              icon: const Icon(Icons.play_circle_outline_rounded),
              selectedIcon: const Icon(Icons.play_circle_rounded),
              label: watchLabel,
            ),

            // 2. Review
            NavigationDestination(
              icon: const Icon(Icons.school_outlined),
              selectedIcon: const Icon(Icons.school_rounded),
              label: reviewLabel,
            ),

            // 3. Vocab
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book_rounded),
              label: vocabLabel,
            ),

            // 4. Library
            NavigationDestination(
              icon: Badge(
                isLabelVisible: hasRewards,
                smallSize: 6,
                backgroundColor: colors.colorFire,
                child: const Icon(Icons.video_library_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: hasRewards,
                smallSize: 6,
                backgroundColor: colors.colorFire,
                child: const Icon(Icons.video_library_rounded),
              ),
              label: libraryLabel,
              tooltip: hasRewards
                  ? '$libraryLabel (${context.t("nav.rewardsAvailable", null, "Rewards available")})'
                  : libraryLabel,
            ),
          ],
        );
      });
  }
}
