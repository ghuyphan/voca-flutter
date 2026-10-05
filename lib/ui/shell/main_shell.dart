// lib/ui/shell/main_shell.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../../state/player_coordinator.dart';
import '../explore/explore_screen.dart';
import '../study/study_deck_screen.dart';
import '../vocabulary/vocabulary_screen.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';
import '../widgets/kikyou_logo.dart';
import '../sheets/new_video_sheet.dart';
import '../sheets/gamification_dialogs.dart';
import '../video/video_navigation_host.dart';
import '../widgets/voca_bottom_nav_bar.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  final GlobalKey<LibraryScreenState> _libraryKey = GlobalKey<LibraryScreenState>();

  late final List<ScrollController> _scrollControllers = List.generate(
    _screens.length,
    (_) => ScrollController(),
  );

  late final List<Widget> _screens = [
    ExploreScreen(
      onOpenPlaylists: () {
        setState(() => _currentIndex = 3);
        _libraryKey.currentState?.switchToPlaylists();
      },
    ),
    StudyDeckScreen(
      onNavigateToExplore: () => setState(() => _currentIndex = 0),
    ),
    const VocabularyScreen(),
    LibraryScreen(
      key: _libraryKey,
      onNavigateToExplore: () => setState(() => _currentIndex = 0),
    ),
  ];

  late final List<Widget> _tabScreens = List.generate(
    _screens.length,
    (i) => PrimaryScrollController(
      controller: _scrollControllers[i],
      child: _screens[i],
    ),
  );

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      _scrollToTop(index);
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _scrollToTop(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (index >= 0 && index < _scrollControllers.length) {
      final controller = _scrollControllers[index];
      if (controller.hasClients && controller.offset > 0.0) {
        controller.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= VocaTokens.tabletBreakpoint;
    final colors = context.vocaColors;

    return Watch((context) {
      final coordinator = PlayerCoordinator.instance;
      final isTrueFullscreen = coordinator.playerController?.isFullscreen.value ?? false;
      final bottomInset = MediaQuery.of(context).padding.bottom;
      final navHeight = (isTablet || isTrueFullscreen) ? 0.0 : (62.0 + bottomInset);

      return VideoNavigationHost(
        bottomNavHeight: navHeight,
        child: Scaffold(
          backgroundColor: colors.bgPrimary,
          body: isTablet ? _buildTabletLayout(context) : _buildMobileLayout(context),
          bottomNavigationBar: (isTablet || isTrueFullscreen)
              ? null
              : _buildMobileBottomNav(context),
        ),
      );
    });
  }

  // ==========================================
  // TABLET / DESKTOP RESPONSIVE LAYOUT (>= 720dp)
  // ==========================================
  Widget _buildTabletLayout(BuildContext context) {
    final colors = context.vocaColors;
    return Row(
      children: [
        // Left Navigation Rail / Sidebar (width ~240dp)
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            border: Border(
              right: BorderSide(color: colors.borderColor, width: 1),
            ),
          ),
          child: _buildTabletSidebar(context),
        ),

        // Main content screen
        Expanded(
          child: IndexedStack(
            index: _currentIndex.clamp(0, _tabScreens.length - 1),
            children: _tabScreens,
          ),
        ),
      ],
    );
  }

  Widget _buildTabletSidebar(BuildContext context) {
    final gamification = AppState.instance.gamificationService;
    final colors = context.vocaColors;

    return SafeArea(
      right: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Brand header: Voca Kikyou flower icon + "VOCA" brand title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                KikyouLogo(size: 28, color: colors.accentPrimary),
                const SizedBox(width: 12),
                Text(
                  'VOCA',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),

          // 2. Elevated "+ New Video" button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () => NewVideoSheet.show(context),
              icon: const Icon(Icons.add, size: 20, color: Colors.white),
              label: Text(
                '+ ${context.t('nav.newVideo', null, 'New Video')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: colors.accentPrimary.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Navigation items
          _buildSidebarNavItem(
            icon: Icons.play_circle_outline,
            activeIcon: Icons.play_circle,
            label: context.t('nav.watch', null, 'Watch'),
            index: 0,
            colors: colors,
          ),
          _buildSidebarNavItem(
            icon: Icons.school_outlined,
            activeIcon: Icons.school,
            label: context.t('nav.review', null, 'Review'),
            index: 1,
            colors: colors,
          ),
          _buildSidebarNavItem(
            icon: Icons.book_outlined,
            activeIcon: Icons.menu_book,
            label: context.t('nav.vocab', null, 'Vocab'),
            index: 2,
            colors: colors,
          ),
          _buildSidebarNavItem(
            icon: Icons.video_library_outlined,
            activeIcon: Icons.video_library_rounded,
            label: context.t('nav.library', null, 'Library'),
            index: 3,
            colors: colors,
          ),

          const Spacer(),

          // 4. Bottom Controls: Language dropdown & stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Language selector dropdown
                Watch((context) {
                  final curLang = AppState.instance.activeLanguage.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: curLang,
                        isExpanded: true,
                        dropdownColor: colors.bgCard,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'ja',
                            child: Text(
                              '🇯🇵 Japanese',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'zh',
                            child: Text(
                              '🇨🇳 Chinese',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'ko',
                            child: Text(
                              '🇰🇷 Korean',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text(
                              '🇺🇸 English',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            AppState.instance.setLanguage(val);
                          }
                        },
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),

                // Unified Motivation & Credits Bar
                Watch((context) {
                  final streak = gamification.currentStreak.value;
                  final diamonds = gamification.diamonds.value;
                  final maxDiamonds = gamification.maxDiamonds.value;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Streak fire counter (🔥 X)
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => showStreakDialog(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Row(
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  '$streak',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Vertical divider
                        Container(
                          width: 1,
                          height: 16,
                          color: colors.borderColor,
                        ),

                        // Diamonds credit (💎 X/5)
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => showAiCreditsDialog(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Row(
                              children: [
                                const Text('💎', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  '$diamonds/$maxDiamonds',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Vertical divider
                        Container(
                          width: 1,
                          height: 16,
                          color: colors.borderColor,
                        ),

                        // Settings gear icon
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.settings_outlined,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                          tooltip: 'Settings',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required VocaColorPalette colors,
  }) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _onTabTapped(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentPrimarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: colors.accentPrimary.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? colors.accentPrimary : colors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? colors.accentPrimary : colors.textSecondary,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MOBILE RESPONSIVE LAYOUT (< 720dp)
  // ==========================================
  Widget _buildMobileLayout(BuildContext context) {
    return IndexedStack(
      index: _currentIndex.clamp(0, _tabScreens.length - 1),
      children: _tabScreens,
    );
  }

  Widget _buildMobileBottomNav(BuildContext context) {
    final activeTab = _currentIndex >= 3 ? 3 : _currentIndex;
    return VocaBottomNavBar(
      currentIndex: activeTab,
      onTabSelected: _onTabTapped,
    );
  }
}
