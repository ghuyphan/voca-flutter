// lib/ui/onboarding/steps/companion_step.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../models/onboarding_models.dart';
import '../widgets/onboarding_primitives.dart';
import '../widgets/pressable_scale.dart';

/// Step 3: Choose companion spirit guide archetype.
/// Features a native horizontal snapping carousel with smooth scale transformations,
/// explicit passive perk explanation, live dialogue speech bubble, and an
/// interactive companion roster comparison sheet.
class CompanionStep extends StatefulWidget {
  final String selectedCompanion;
  final ValueChanged<String> onCompanionChanged;

  const CompanionStep({
    super.key,
    required this.selectedCompanion,
    required this.onCompanionChanged,
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
      viewportFraction: 0.70,
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

  void _showRosterSheet(BuildContext context, VocaColorPalette colors) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.bgCard,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.90,
          builder: (_, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  // Sheet Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: colors.accentPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.t(
                            'onboarding.companionPerksGuide',
                            null,
                            'Spirit Guide Perks',
                          ),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Roster List
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: CompanionOption.all.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final comp = CompanionOption.all[index];
                        final isSelected = index == _currentPage;
                        final name = context.t(comp.nameKey, null, comp.id);
                        final trait = context.t(comp.traitKey, null, '');
                        final perk = context.t(comp.perkKey, null, '');

                        return InkWell(
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? comp.color.withValues(alpha: colors.isDark ? 0.16 : 0.08)
                                  : colors.bgSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? comp.color : colors.borderColorLight,
                                width: isSelected ? 1.6 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: comp.color, width: 1.5),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      comp.avatarAsset,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        comp.icon,
                                        size: 22,
                                        color: comp.color,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Name & Perk Text
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TagChip(
                                            label: trait,
                                            bg: comp.color.withValues(
                                                alpha: colors.isDark ? 0.16 : 0.10),
                                            fg: comp.color,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        perk,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: colors.textSecondary,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded,
                                      color: comp.color, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.isDark;
    final activeCompanion = CompanionOption.all[_currentPage];
    final activeQuote = context.t(activeCompanion.quoteKey, null, '');
    final activeTrait = context.t(activeCompanion.traitKey, null, '');
    final activePerk = context.t(activeCompanion.perkKey, null, '');

    return OnboardingStepLayout(
      title: context.t('onboarding.companionTitle', null, 'Choose Your Companion'),
      subtitle: context.t(
        'onboarding.companionSubtitle',
        null,
        'Your companion guide brings unique passive mastery to your journey',
      ),
      children: [
        // Roster comparison button row
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _showRosterSheet(context, colors),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.borderColorLight, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: colors.accentPrimary),
                    const SizedBox(width: 5),
                    Text(
                      context.t(
                        'onboarding.companionPerksGuide',
                        null,
                        'Spirit Guide Perks',
                      ),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: colors.accentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

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

        const SizedBox(height: 12),

        // 2. Mini Jump Indicator Dots
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
                        width: i == _currentPage ? 24 : 6,
                        height: 6,
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

        const SizedBox(height: 16),

        // 3. Dedicated Passive Perk Explanation Card
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: Container(
            key: ValueKey('perk_${activeCompanion.id}'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activeCompanion.color.withValues(alpha: isDark ? 0.40 : 0.25),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeCompanion.color.withValues(alpha: isDark ? 0.16 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: activeCompanion.color.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    size: 20,
                    color: activeCompanion.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            context.t('onboarding.passivePerk', null, 'Passive Perk').toUpperCase(),
                            style: TextStyle(
                              color: activeCompanion.color,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            activeTrait,
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        activePerk,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 4. Live Companion Dialogue Speech Bubble
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: Container(
            key: ValueKey('quote_${activeCompanion.id}'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: activeCompanion.color
                  .withValues(alpha: isDark ? 0.10 : 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: activeCompanion.color.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 15,
                  color: activeCompanion.color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '“$activeQuote”',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12.5,
                      height: 1.35,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            borderRadius: BorderRadius.circular(20),
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
                : [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: colors.isDark ? 0.20 : 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                    width: 74,
                    height: 74,
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
                        width: 74,
                        height: 74,
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
                        horizontal: 8,
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

              const SizedBox(height: 5),

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
