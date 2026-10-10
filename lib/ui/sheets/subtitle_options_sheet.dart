// lib/ui/sheets/subtitle_options_sheet.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../state/player_state.dart';
import '../../utils/language_utils.dart';
import 'video_settings_sheet.dart';
import 'voca_bottom_sheet.dart';

class SubtitleOptionsSheet extends StatefulWidget {
  final VideoPlayerController controller;
  final YoutubePlayerController ytController;

  const SubtitleOptionsSheet({
    super.key,
    required this.controller,
    required this.ytController,
  });

  static Future<void> show(
    BuildContext context, {
    required VideoPlayerController controller,
    required YoutubePlayerController ytController,
  }) {
    return showVocaBottomSheet(
      context: context,
      title: context.t('settings.subtitles'),
      showCloseButton: true,
      contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      builder: (_) => SubtitleOptionsSheet(
        controller: controller,
        ytController: ytController,
      ),
    );
  }

  @override
  State<SubtitleOptionsSheet> createState() => _SubtitleOptionsSheetState();
}

class _SubtitleOptionsSheetState extends State<SubtitleOptionsSheet> {
  String _getReadingIcon(String lang) {
    switch (lang) {
      case 'ja':
        return 'あ';
      case 'zh':
        return '拼';
      case 'ko':
        return '한';
      default:
        return 'Aa';
    }
  }

  String _getReadingTitle(BuildContext context, String lang) {
    switch (lang) {
      case 'ja':
        return 'Furigana';
      case 'zh':
        return 'Pinyin';
      case 'ko':
        return 'Romaja';
      default:
        return context.t('subtitle.readingGuide', null, 'Reading Guide');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = widget.controller.activeLanguage.value;
    final colors = context.vocaColors;

    return SingleChildScrollView(
      child: Watch((context) {
        final subtitleSize = widget.controller.subtitleSize.value;
        final showFurigana = widget.controller.showFurigana.value;
        final readingMode = widget.controller.readingDisplayMode.value;
        final grammarMode = widget.controller.grammarModeEnabled.value;
        final showTranslation = widget.controller.showTranslation.value;
        final rate = widget.controller.playbackRate.value;
        final isReadingActive = showFurigana && readingMode != 'native';

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Font Size Segmented Control
            Text(
              context.t('settings.subtitleSize', null, 'Subtitle Size').toUpperCase(),
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSizeOption(
                  colors: colors,
                  label: context.t('settings.sizeSmall', null, 'Small'),
                  sample: 'Aa',
                  isSelected: subtitleSize == SubtitleSize.small,
                  onTap: () => widget.controller.subtitleSize.value = SubtitleSize.small,
                ),
                const SizedBox(width: 8),
                _buildSizeOption(
                  colors: colors,
                  label: context.t('settings.sizeMedium', null, 'Medium'),
                  sample: 'Aa',
                  isSelected: subtitleSize == SubtitleSize.medium,
                  onTap: () => widget.controller.subtitleSize.value = SubtitleSize.medium,
                ),
                const SizedBox(width: 8),
                _buildSizeOption(
                  colors: colors,
                  label: context.t('settings.sizeLarge', null, 'Large'),
                  sample: 'Aa',
                  isSelected: subtitleSize == SubtitleSize.large,
                  onTap: () => widget.controller.subtitleSize.value = SubtitleSize.large,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. Playback Speed Selector
            Text(
              context.t('player.speed').toUpperCase(),
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [0.75, 1.0, 1.25, 1.5].map((speed) {
                final isSelected = (rate - speed).abs() < 0.05;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        widget.controller.playbackRate.value = speed;
                        widget.ytController.setPlaybackRate(speed);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? colors.accentPrimary : colors.bgSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? colors.accentPrimary : colors.borderColor,
                          ),
                        ),
                        child: Text(
                          '${speed}x',
                          style: TextStyle(
                            color: isSelected ? Colors.white : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // 3. Display Toggles Card
            Text(
              context.t('subtitle.display', null, 'Display').toUpperCase(),
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: colors.bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: colors.borderColor),
              ),
              child: Column(
                children: [
                  // Reading / Furigana toggle
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    secondary: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.borderColor),
                      ),
                      child: Text(
                        _getReadingIcon(currentLang),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    title: Text(
                      _getReadingTitle(context, currentLang),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      isReadingActive
                          ? getReadingDisplayLabel(readingMode, currentLang, context)
                          : context.t('settings.readingDisplayDesc'),
                      style: TextStyle(color: colors.textMuted, fontSize: 11.5),
                    ),
                    value: isReadingActive,
                    onChanged: (_) => widget.controller.toggleFurigana(),
                  ),
                  Divider(height: 1, color: colors.borderColorLight),

                  // Grammar Mode toggle
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    secondary: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.borderColor),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: colors.textSecondary,
                        size: 17,
                      ),
                    ),
                    title: Text(
                      context.t('grammar.title'),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      context.t('grammar.highlightDesc', null, 'Highlight detected JLPT / HSK / TOPIK / CEFR grammar rules'),
                      style: TextStyle(color: colors.textMuted, fontSize: 11.5),
                    ),
                    value: grammarMode,
                    onChanged: (val) {
                      widget.controller.setGrammarMode(val);
                    },
                  ),
                  Divider(height: 1, color: colors.borderColorLight),

                  // Dual Subtitle Translation toggle
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    secondary: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.borderColor),
                      ),
                      child: Icon(
                        Icons.translate_rounded,
                        color: colors.textSecondary,
                        size: 17,
                      ),
                    ),
                    title: Text(
                      context.t('settings.dualSubtitles', null, 'Secondary Subtitles'),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      context.t('settings.dualSubtitlesDesc'),
                      style: TextStyle(color: colors.textMuted, fontSize: 11.5),
                    ),
                    value: showTranslation,
                    onChanged: (_) => widget.controller.toggleTranslation(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. More Video Settings Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  VideoSettingsSheet.show(
                    context,
                    controller: widget.controller,
                    ytController: widget.ytController,
                  );
                },
                icon: Icon(Icons.settings_rounded, size: 16, color: colors.textSecondary),
                label: Text(
                  context.t('player.settings', null, 'Cài đặt video & phát lại'),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        );
      }),
    );
  }

  Widget _buildSizeOption({
    required VocaColorPalette colors,
    required String label,
    required String sample,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary : colors.bgSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? colors.accentPrimary : colors.borderColor,
              width: 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.accentPrimary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                sample,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textPrimary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
