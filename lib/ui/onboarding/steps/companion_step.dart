// lib/ui/onboarding/steps/companion_step.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../models/onboarding_models.dart';
import '../widgets/onboarding_primitives.dart';
import '../widgets/pressable_scale.dart';

/// Step 4: Choose companion spirit guide archetype & appearance theme.
/// Features a native horizontal snapping carousel with smooth scale transformations,
/// companion speech bubble, dot jump-pills, and theme personalization (System / Light / Dark).
class CompanionStep extends StatefulWidget {
  final String selectedCompanion;
  final ValueChanged<String> onCompanionChanged;
  final String themeMode;
  final ValueChanged<String>? onThemeChanged;

  const CompanionStep({
    super.key,
    required this.selectedCompanion,
    required this.onCompanionChanged,
    this.themeMode = 'system',
    this.onThemeChanged,
  });

  @override
  State<CompanionStep> createState() => _CompanionStepState();
}

class _CompanionStepState extends State<CompanionStep> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = CompanionOption.indexOf(widget.selectedCompanion);
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.68,
    );
  }

  @override
  void didUpdateWidget(covariant CompanionStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCompanion != widget.selectedCompanion) {
      final target = CompanionOption.indexOf(widget.selectedCompanion);
      if (target != _currentPage && _pageController.hasClients) {
        _pageController.animateToPage(
          target,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    HapticFeedback.selectionClick();
    widget.onCompanionChanged(CompanionOption.all[page].id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activeCompanion = CompanionOption.all[_currentPage];
    final activeQuote = context.t(activeCompanion.quoteKey, null, '');
    final effectiveTheme =
        (widget.themeMode == 'light' || widget.themeMode == 'dark')
            ? widget.themeMode
            : 'system';

    return OnboardingStepLayout(
      title: context.t('onboarding.companionTitle', null, 'Choose Your Companion'),
      subtitle: context.t(
        'onboarding.companionSubtitle',
        null,
        'Your companion guide brings unique passive mastery to your journey',
      ),
      children: [
        // 1. Horizontal snapping companion carousel
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: CompanionOption.all.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final comp = CompanionOption.all[index];
              final isCurrent = index == _currentPage;

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double scale = 1.0;
                  if (_pageController.position.haveDimensions) {
                    final page = _pageController.page ?? _currentPage.toDouble();
                    final diff = (page - index).abs().clamp(0.0, 1.0);
                    scale = 1.0 - (diff * 0.12);
                  } else {
                    scale = isCurrent ? 1.0 : 0.88;
                  }

                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: _CompanionCarouselCard(
                  companion: comp,
                  isSelected: isCurrent,
                  colors: colors,
                  onTap: () {
                    if (!isCurrent) {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // 2. Live Companion Speech Bubble
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: Container(
            key: ValueKey(activeCompanion.id),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: activeCompanion.color
                  .withValues(alpha: colors.isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activeCompanion.color.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: activeCompanion.color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '“$activeQuote”',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      height: 1.35,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 3. Mini Avatar Jump Dots
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < CompanionOption.all.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == _currentPage ? 26 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? activeCompanion.color
                              : colors.borderColorHover,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 4. Appearance & Theme Selection
        SectionLabel(
          context.t('onboarding.appearance', null, 'Giao diện hiển thị'),
        ),
        Row(
          children: [
            _ThemeOptionTile(
              icon: Icons.brightness_auto_outlined,
              label: context.t('onboarding.themeSystem', null, 'Hệ thống'),
              subtitle:
                  context.t('onboarding.themeSystemDesc', null, 'Tự động'),
              isSelected: effectiveTheme == 'system',
              onTap: () => widget.onThemeChanged?.call('system'),
            ),
            const SizedBox(width: 8),
            _ThemeOptionTile(
              icon: Icons.light_mode_outlined,
              label: context.t('onboarding.themeLight', null, 'Sáng'),
              subtitle:
                  context.t('onboarding.themeLightDesc', null, 'Giao diện sáng'),
              isSelected: effectiveTheme == 'light',
              onTap: () => widget.onThemeChanged?.call('light'),
            ),
            const SizedBox(width: 8),
            _ThemeOptionTile(
              icon: Icons.dark_mode_outlined,
              label: context.t('onboarding.themeDark', null, 'Tối'),
              subtitle:
                  context.t('onboarding.themeDarkDesc', null, 'Giao diện tối'),
              isSelected: effectiveTheme == 'dark',
              onTap: () => widget.onThemeChanged?.call('dark'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompanionCarouselCard extends StatelessWidget {
  final CompanionOption companion;
  final bool isSelected;
  final VocaColorPalette colors;
  final VoidCallback onTap;

  const _CompanionCarouselCard({
    required this.companion,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = context.t(companion.nameKey, null, companion.id);
    final trait = context.t(companion.traitKey, null, '');

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$name, $trait',
      child: PressableScale(
        onTap: onTap,
        pressedScale: 0.97,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? companion.color : colors.borderColor,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: companion.color
                          .withValues(alpha: colors.isDark ? 0.30 : 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar with circle border & Lv.1 pill
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: companion.color
                          .withValues(alpha: colors.isDark ? 0.20 : 0.12),
                      border: Border.all(
                        color: companion.color,
                        width: 2.2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        companion.avatarAsset,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          companion.icon,
                          size: 36,
                          color: companion.color,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: companion.color, width: 1.2),
                      ),
                      child: Text(
                        'Lv.1',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: companion.color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 4),

              TagChip(
                label: trait,
                bg: companion.color
                    .withValues(alpha: colors.isDark ? 0.16 : 0.10),
                fg: companion.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;

    final border = isSelected
        ? Border.all(color: colors.accentPrimary, width: 1.6)
        : Border.all(color: colors.borderColorLight, width: 1.0);

    final bg = isSelected
        ? colors.accentPrimary.withValues(alpha: isDark ? 0.20 : 0.08)
        : colors.bgCard;

    final textColor = isSelected ? colors.accentPrimary : colors.textPrimary;
    final iconColor = isSelected ? colors.accentPrimary : colors.textSecondary;

    return Expanded(
      child: PressableScale(
        haptic: true,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: border,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: isSelected
                      ? colors.accentPrimary.withValues(alpha: 0.8)
                      : colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
