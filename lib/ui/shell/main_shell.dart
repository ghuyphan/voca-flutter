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
import '../video/miniplayer_bar.dart';
import '../video/video_player_screen.dart';
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

  late final List<Widget> _screens = [
    ExploreScreen(
      onOpenPlaylists: () => setState(() => _currentIndex = 4),
    ),
    const StudyDeckScreen(),
    const VocabularyScreen(),
    const SettingsScreen(),
    LibraryScreen(
      key: const ValueKey('library_playlists_tab'),
      initialTabIndex: 1,
      onNavigateToExplore: () => setState(() => _currentIndex = 0),
    ),
    LibraryScreen(
      key: const ValueKey('library_history_tab'),
      initialTabIndex: 0,
      onNavigateToExplore: () => setState(() => _currentIndex = 0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= VocaTokens.tabletBreakpoint;
    final colors = context.vocaColors;

    return Watch((context) {
      final coordinator = PlayerCoordinator.instance;
      final hasActive = coordinator.hasActiveVideo;
      final isMini = coordinator.isMiniplayer.value;
      final isTrueFullscreen = coordinator.playerController?.isFullscreen.value ?? false;
      final videoId = coordinator.activeVideoId.value;

      return Scaffold(
        backgroundColor: colors.bgPrimary,
        body: Stack(
          children: [
            isTablet ? _buildTabletLayout(context) : _buildMobileLayout(context),
            if (hasActive && videoId != null) ...[
              Positioned.fill(
                child: Visibility(
                  visible: !isMini,
                  maintainState: true,
                  child: VideoPlayerScreen(
                    key: ValueKey(videoId),
                    videoId: videoId,
                    title: coordinator.activeTitle.value,
                    channel: coordinator.activeChannel.value,
                    level: coordinator.activeLevel.value,
                    playlistTitle: coordinator.activePlaylistTitle.value,
                    playlistIndex: coordinator.activePlaylistIndex.value,
                    playlistTotal: coordinator.activePlaylistTotal.value,
                    sharedPlayerController: coordinator.playerController,
                    sharedYtController: coordinator.ytController,
                  ),
                ),
              ),
              if (isMini)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: MiniplayerBar(
                    videoId: videoId,
                    title: coordinator.activeTitle.value,
                    channel: coordinator.activeChannel.value ?? 'YouTube',
                    currentTime: coordinator.currentTime.value,
                    duration: coordinator.duration.value,
                    isPlaying: coordinator.isPlaying.value,
                    isEnded: coordinator.isEnded.value,
                    onTap: () => coordinator.expand(context),
                    onPlayPause: () => coordinator.togglePlayPause(),
                    onClose: () => coordinator.closeVideo(),
                  ),
                ),
            ],
          ],
        ),
        bottomNavigationBar: (isTablet || isTrueFullscreen)
            ? null
            : _buildMobileBottomNav(context),
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
            index: _currentIndex.clamp(0, _screens.length - 1),
            children: _screens,
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
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: context.t('nav.more', null, 'More'),
            index: 3,
            colors: colors,
          ),
          _buildSidebarNavItem(
            icon: Icons.playlist_play,
            activeIcon: Icons.playlist_play_rounded,
            label: context.t('nav.playlists', null, 'Playlists'),
            index: 4,
            colors: colors,
          ),
          _buildSidebarNavItem(
            icon: Icons.history,
            activeIcon: Icons.history_rounded,
            label: context.t('history.title', null, 'History'),
            index: 5,
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
      index: _currentIndex.clamp(0, _screens.length - 1),
      children: _screens,
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
