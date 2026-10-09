import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../../widgets/voca_back_button.dart';
import '../models/onboarding_models.dart';
import 'onboarding_primitives.dart';

/// Top bar: back button · segmented progress · skip · optional locale selector.
/// [progress] is 1-based; pass 0 to hide the progress bar (Welcome step).
class OnboardingHeader extends StatelessWidget {
  final int progress;
  final int totalSegments;
  final bool showBack;
  final bool showSkip;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final String? currentLanguage;
  final ValueChanged<String>? onLanguageChanged;

  const OnboardingHeader({
    super.key,
    required this.progress,
    required this.totalSegments,
    required this.showBack,
    required this.showSkip,
    required this.onBack,
    required this.onSkip,
    this.currentLanguage,
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Back (M3 48x48 min touch target)
            SizedBox(
              width: 48,
              height: 48,
              child: AnimatedOpacity(
                opacity: showBack ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !showBack,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: VocaBackButton(
                      onPressed: onBack,
                      tooltip: context.t('onboarding.back', null, 'Back'),
                    ),
                  ),
                ),
              ),
            ),

            // Progress
            Expanded(
              child: AnimatedOpacity(
                opacity: progress > 0 ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Semantics(
                  label: context.t(
                    'onboarding.stepProgress',
                    {'current': progress, 'total': totalSegments},
                    'Step $progress of $totalSegments',
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: List.generate(totalSegments, (i) {
                        final filled = i < progress;
                        return Expanded(
                          child: Container(
                            height: 5,
                            margin: EdgeInsets.only(
                              right: i == totalSegments - 1 ? 0 : 5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.bgTertiary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.centerLeft,
                            child: AnimatedFractionallySizedBox(
                              duration: const Duration(milliseconds: 420),
                              curve: const Cubic(0.16, 1.0, 0.3, 1.0),
                              widthFactor: filled ? 1 : 0,
                              heightFactor: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colors.accentPrimary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),

            // Locale Switcher (Step 0)
            if (progress == 0 && onLanguageChanged != null) ...[
              _LanguagePickerPill(
                currentCode: currentLanguage ?? I18nService.instance.currentLanguage.value,
                onSelect: onLanguageChanged!,
                colors: colors,
              ),
              const SizedBox(width: 8),
            ],

            // Skip
            SizedBox(
              width: 64,
              height: 48,
              child: AnimatedOpacity(
                opacity: showSkip ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !showSkip,
                  child: TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: colors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(context.t('onboarding.skip', null, 'Skip')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguagePickerPill extends StatelessWidget {
  final String currentCode;
  final ValueChanged<String> onSelect;
  final VocaColorPalette colors;

  const _LanguagePickerPill({
    required this.currentCode,
    required this.onSelect,
    required this.colors,
  });

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.bgCard,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    context.t('settings.language', null, 'App Language'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final opt in NativeLanguageOption.all)
                  InkWell(
                    onTap: () {
                      onSelect(opt.code);
                      Navigator.of(ctx).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: currentCode == opt.code
                            ? colors.accentPrimary.withValues(alpha: colors.isDark ? 0.14 : 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          RoundFlag(asset: opt.flagAsset, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt.nativeName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: currentCode == opt.code ? FontWeight.w700 : FontWeight.w500,
                                    color: currentCode == opt.code ? colors.accentPrimary : colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  opt.englishName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (currentCode == opt.code)
                            Icon(Icons.check_rounded, color: colors.accentPrimary, size: 20),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final opt = NativeLanguageOption.byCode(currentCode);

    return SizedBox(
      height: 48,
      child: Center(
        child: InkWell(
          onTap: () => _showLanguageSheet(context),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.borderColorLight, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoundFlag(asset: opt.flagAsset, size: 16),
                const SizedBox(width: 6),
                Text(
                  opt.code.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
