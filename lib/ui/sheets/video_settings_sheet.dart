// lib/ui/sheets/video_settings_sheet.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../../state/player_state.dart';
import '../../utils/language_utils.dart';
import '../settings/offline_translation_screen.dart';
import 'add_to_playlist_sheet.dart';
import 'voca_bottom_sheet.dart';
import '../widgets/circle_flag.dart';

/// YouTube-style nested multi-panel settings sheet.
/// Ported 1:1 from lingua-tube's playerSettingsTemplate:
/// - Main panel: Speed, Subtitle Size, Dual Subtitles (with flag), Reading mode,
///   Grammar mode, Sleep timer, Save to playlist, Share video.
/// - Sub-panels with back button: 'speed', 'fontSize', 'dualSub', 'reading', 'grammar', 'sleepTimer'.
class VideoSettingsSheet extends StatefulWidget {
  final VideoPlayerController controller;
  final YoutubePlayerController ytController;
  final VoidCallback? onSaveToPlaylist;
  final VoidCallback? onShare;

  const VideoSettingsSheet({
    super.key,
    required this.controller,
    required this.ytController,
    this.onSaveToPlaylist,
    this.onShare,
  });

  static Future<void> show(
    BuildContext context, {
    required VideoPlayerController controller,
    required YoutubePlayerController ytController,
    VoidCallback? onSaveToPlaylist,
    VoidCallback? onShare,
  }) {
    return showVocaBottomSheet(
      context: context,
      showCloseButton: false,
      maxHeightFactor: 0.85,
      contentPadding: EdgeInsets.zero,
      builder: (ctx) => VideoSettingsSheet(
        controller: controller,
        ytController: ytController,
        onSaveToPlaylist: onSaveToPlaylist,
        onShare: onShare,
      ),
    );
  }

  @override
  State<VideoSettingsSheet> createState() => _VideoSettingsSheetState();
}

class _VideoSettingsSheetState extends State<VideoSettingsSheet> {
  String _currentView = 'main'; // 'main', 'speed', 'fontSize', 'dualSub', 'reading', 'grammar', 'sleepTimer'

  static const List<double> _playbackSpeeds = [
    0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0
  ];

  String _getReadingScriptIcon(String lang) {
    switch (lang.toLowerCase()) {
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

  String _getReadingModeName(String lang) {
    switch (lang.toLowerCase()) {
      case 'ja':
        return 'Furigana';
      case 'zh':
        return 'Pinyin';
      case 'ko':
        return 'Romaja';
      default:
        return 'Reading Guide';
    }
  }

  String _getFontSizeName(SubtitleSize size) {
    switch (size) {
      case SubtitleSize.small:
        return context.t('settings.sizeSmall', null, 'Nhỏ');
      case SubtitleSize.medium:
        return context.t('settings.sizeMedium', null, 'Vừa');
      case SubtitleSize.large:
        return context.t('settings.sizeLarge', null, 'Lớn');
    }
  }

  String _getTargetLangName(String langCode) {
    final found = SubtitleLanguageOption.findByCode(langCode);
    return found?.name ?? langCode.toUpperCase();
  }

  void _handleSaveToPlaylist() {
    Navigator.pop(context);
    if (widget.onSaveToPlaylist != null) {
      widget.onSaveToPlaylist!();
      return;
    }
    final videoId = widget.controller.videoId;
    if (videoId.isNotEmpty) {
      AddToPlaylistSheet.show(context, videoId: videoId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _buildCurrentView(context),
    );
  }

  Widget _buildCurrentView(BuildContext context) {
    switch (_currentView) {
      case 'speed':
        return _buildSpeedPanel(context);
      case 'fontSize':
        return _buildFontSizePanel(context);
      case 'dualSub':
        return _buildDualSubPanel(context);
      case 'reading':
        return _buildReadingPanel(context);
      case 'grammar':
        return _buildGrammarPanel(context);
      case 'sleepTimer':
        return _buildSleepTimerPanel(context);
      case 'main':
      default:
        return _buildMainPanel(context);
    }
  }

  // ==========================================
  // PANEL HEADER WITH BACK BUTTON
  // ==========================================
  Widget _buildPanelHeader({
    required BuildContext context,
    required String title,
    IconData? icon,
  }) {
    final colors = context.vocaColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _currentView = 'main'),
            icon: Icon(Icons.arrow_back_rounded, size: 20, color: colors.textPrimary),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: const EdgeInsets.all(10),
            tooltip: context.t('common.back', null, 'Back'),
          ),
          const SizedBox(width: 4),
          if (icon != null) ...[
            Icon(icon, size: 18, color: colors.accentPrimary),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. MAIN PANEL
  // ==========================================
  Widget _buildMainPanel(BuildContext context) {
    final colors = context.vocaColors;
    final currentLang = widget.controller.activeLanguage.value;

    return Watch((context) {
      final currentSpeed = widget.controller.playbackRate.value;
      final fontSize = widget.controller.subtitleSize.value;
      final showDual = widget.controller.showTranslation.value;
      final showReading = widget.controller.showFurigana.value;
      final targetLang = widget.controller.dualSubLanguage.value ?? 'en';

      final speedLabel = (currentSpeed - 1.0).abs() < 0.05
          ? (context.t('player.normalSpeed', null, 'Bình thường (1x)'))
          : '${currentSpeed}x';

      final readingLabel = showReading
          ? _getReadingModeName(currentLang)
          : (context.t('player.off', null, 'Tắt'));

      final dualSubLabel = showDual
          ? _getTargetLangName(targetLang)
          : (context.t('player.off', null, 'Tắt'));

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 20, color: colors.accentPrimary),
                  const SizedBox(width: 10),
                  Text(
                    context.t('player.settings', null, 'Cài đặt'),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.borderColor),

            // 1. Playback Speed
            _buildMenuItem(
              context: context,
              icon: Icons.speed_rounded,
              label: context.t('player.playbackSpeed', null, 'Tốc độ phát'),
              value: speedLabel,
              onTap: () => setState(() => _currentView = 'speed'),
            ),

            // 2. Subtitle Size
            _buildMenuItem(
              context: context,
              icon: Icons.format_size_rounded,
              label: context.t('subtitle.fontSize', null, 'Cỡ chữ'),
              value: _getFontSizeName(fontSize),
              onTap: () => setState(() => _currentView = 'fontSize'),
            ),

            // 3. Dual Subtitles
            _buildMenuItem(
              context: context,
              icon: Icons.translate_rounded,
              label: context.t('subtitle.dualSubs', null, 'Phụ đề song ngữ'),
              value: dualSubLabel,
              leadingValueWidget: showDual ? CircleFlag(code: targetLang, size: 16) : null,
              onTap: () => setState(() => _currentView = 'dualSub'),
            ),

            // 4. Reading Display (Furigana / Pinyin / Romaji)
            _buildMenuItem(
              context: context,
              icon: Icons.text_fields_rounded,
              label: _getReadingModeName(currentLang),
              value: readingLabel,
              onTap: () => setState(() => _currentView = 'reading'),
            ),

            // 5. Grammar Mode
            _buildMenuItem(
              context: context,
              icon: Icons.auto_awesome_rounded,
              label: context.t('grammar.mode', null, 'Ngữ pháp'),
              value: context.t('common.on', null, 'Bật'),
              onTap: () => setState(() => _currentView = 'grammar'),
            ),

            // 6. Sleep Timer
            _buildMenuItem(
              context: context,
              icon: Icons.timer_outlined,
              label: context.t('player.sleepTimer', null, 'Hẹn giờ ngủ'),
              value: widget.controller.sleepTimerOption.value == 'off'
                  ? context.t('player.off', null, 'Tắt')
                  : (widget.controller.sleepTimerOption.value == 'end'
                      ? 'Kết thúc video'
                      : '${widget.controller.sleepTimerOption.value} phút'),
              onTap: () => setState(() => _currentView = 'sleepTimer'),
            ),

            Divider(height: 1, color: colors.borderColor),

            // 7. Save to Playlist (Exact Pic 4 bottom item)
            _buildMenuItem(
              context: context,
              icon: Icons.playlist_add_rounded,
              label: context.t('playlist.saveToPlaylist', null, 'Lưu vào danh sách phát'),
              onTap: _handleSaveToPlaylist,
            ),

            const SizedBox(height: 16),
          ],
        ),
      );
    });
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? value,
    Widget? leadingValueWidget,
    required VoidCallback onTap,
  }) {
    final colors = context.vocaColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
            if (leadingValueWidget != null) ...[
              leadingValueWidget,
              const SizedBox(width: 6),
            ],
            if (value != null) ...[
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(Icons.chevron_right_rounded, size: 18, color: colors.textMuted),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. SPEED PANEL
  // ==========================================
  Widget _buildSpeedPanel(BuildContext context) {
    final currentSpeed = widget.controller.playbackRate.value;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPanelHeader(
            context: context,
            title: context.t('player.playbackSpeed', null, 'Playback speed'),
            icon: Icons.speed_rounded,
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _playbackSpeeds.length,
            itemBuilder: (context, index) {
              final speed = _playbackSpeeds[index];
              final isSelected = (currentSpeed - speed).abs() < 0.05;
              final label = speed == 1.0
                  ? context.t('player.normal', null, 'Normal')
                  : '${speed}x';

              return _buildOptionRow(
                context: context,
                label: label,
                isSelected: isSelected,
                onTap: () {
                  widget.controller.playbackRate.value = speed;
                  widget.ytController.setPlaybackRate(speed);
                  setState(() => _currentView = 'main');
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ==========================================
  // 3. FONT SIZE PANEL
  // ==========================================
  Widget _buildFontSizePanel(BuildContext context) {
    final currentSize = widget.controller.subtitleSize.value;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPanelHeader(
            context: context,
            title: context.t('subtitle.fontSize', null, 'Subtitle size'),
            icon: Icons.format_size_rounded,
          ),
          _buildOptionRow(
            context: context,
            label: context.t('settings.sizeSmall', null, 'Small'),
            isSelected: currentSize == SubtitleSize.small,
            onTap: () {
              widget.controller.subtitleSize.value = SubtitleSize.small;
              setState(() => _currentView = 'main');
            },
          ),
          _buildOptionRow(
            context: context,
            label: context.t('settings.sizeMedium', null, 'Medium'),
            isSelected: currentSize == SubtitleSize.medium,
            onTap: () {
              widget.controller.subtitleSize.value = SubtitleSize.medium;
              setState(() => _currentView = 'main');
            },
          ),
          _buildOptionRow(
            context: context,
            label: context.t('settings.sizeLarge', null, 'Large'),
            isSelected: currentSize == SubtitleSize.large,
            onTap: () {
              widget.controller.subtitleSize.value = SubtitleSize.large;
              setState(() => _currentView = 'main');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ==========================================
  // 4. DUAL SUBTITLES PANEL
  // ==========================================
  Widget _buildDualSubPanel(BuildContext context) {
    final colors = context.vocaColors;
    final showDual = widget.controller.showTranslation.value;
    final currentTarget = widget.controller.dualSubLanguage.value ?? 'en';
    final activeLearningLang = widget.controller.activeLanguage.value.toLowerCase();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPanelHeader(
            context: context,
            title: context.t('subtitle.dualSubs', null, 'Dual Subtitles'),
            icon: Icons.translate_rounded,
          ),

          // Off option
          _buildOptionRow(
            context: context,
            label: context.t('player.off', null, 'Off'),
            isSelected: !showDual,
            leading: Icon(Icons.block_rounded, size: 18, color: colors.textMuted),
            onTap: () {
              widget.controller.showTranslation.value = false;
              setState(() => _currentView = 'main');
            },
          ),

          Divider(height: 1, color: colors.borderColor),

          // Target language options with circle flags
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kSupportedSubtitleLanguages.length,
            itemBuilder: (context, index) {
              final item = kSupportedSubtitleLanguages[index];
              final code = item.code;
              final locName = item.getLocalizedName(context);
              final displayName = locName == item.name ? item.name : '$locName (${item.name})';
              final isLearningLang = code == activeLearningLang;
              final isSelected = showDual && currentTarget == code;

              final onDeviceService = AppState.instance.onDeviceTranslationService;
              final isDownloaded = onDeviceService.downloadedLanguages.value.contains(code);
              final isDownloading = onDeviceService.downloadingLanguages.value.contains(code);

              Widget? trailing;
              if (item.isBuiltIn) {
                trailing = Text(
                  context.t('settings.builtIn', null, 'Built-in'),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                );
              } else if (isDownloading) {
                trailing = SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.accentPrimary,
                  ),
                );
              } else if (isDownloaded) {
                trailing = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.offline_pin_outlined, size: 15, color: colors.colorGrammar),
                    const SizedBox(width: 4),
                    Text(
                      context.t('settings.offlineBadge', null, 'On-Device'),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.colorGrammar,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              } else {
                trailing = IconButton(
                  icon: Icon(Icons.cloud_download_outlined, size: 18, color: colors.textMuted),
                  tooltip: context.t(
                    'settings.downloadModelTooltip',
                    {'name': locName},
                    'Download $locName model (~30 MB)',
                  ),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    onDeviceService.downloadModel(code);
                  },
                );
              }

              return _buildOptionRow(
                context: context,
                label: displayName,
                isSelected: isSelected,
                isDisabled: isLearningLang,
                leading: CircleFlag(code: code, size: 20),
                trailing: trailing,
                onTap: () {
                  widget.controller.setDualSubLanguage(code);
                  widget.controller.showTranslation.value = true;
                  setState(() => _currentView = 'main');
                },
              );
            },
          ),
          Divider(height: 1, color: colors.borderColor),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            leading: Icon(Icons.download_for_offline_outlined, color: colors.accentPrimary, size: 22),
            title: Text(
              context.t('settings.manageOfflineModels', null, 'Manage On-Device Models'),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              context.t('settings.offlineDescSub', null, 'Download language models for instant subtitles'),
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: colors.textMuted, size: 20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OfflineTranslationScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ==========================================
  // 5. READING PANEL
  // ==========================================
  Widget _buildReadingPanel(BuildContext context) {
    final colors = context.vocaColors;
    final currentLang = widget.controller.activeLanguage.value;
    final showReading = widget.controller.showFurigana.value;
    final readingTitle = _getReadingModeName(currentLang);
    final scriptIcon = _getReadingScriptIcon(currentLang);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPanelHeader(
            context: context,
            title: readingTitle,
            icon: Icons.text_fields_rounded,
          ),

          // Off
          _buildOptionRow(
            context: context,
            label: context.t('player.off', null, 'Off'),
            isSelected: !showReading,
            leading: Icon(Icons.block_rounded, size: 18, color: colors.textMuted),
            onTap: () {
              widget.controller.showFurigana.value = false;
              setState(() => _currentView = 'main');
            },
          ),

          // Annotated (Furigana / Pinyin / Romaja)
          _buildOptionRow(
            context: context,
            label: readingTitle,
            isSelected: showReading,
            leading: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.accentPrimarySoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                scriptIcon,
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            onTap: () {
              widget.controller.showFurigana.value = true;
              setState(() => _currentView = 'main');
            },
          ),

          // Romaji option for Japanese
          if (currentLang.toLowerCase() == 'ja')
            _buildOptionRow(
              context: context,
              label: 'Romaji',
              isSelected: false,
              leading: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Text(
                  'Aa',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              onTap: () {
                widget.controller.showFurigana.value = true;
                setState(() => _currentView = 'main');
              },
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ==========================================
  // 6. GRAMMAR PANEL
  // ==========================================
  Widget _buildGrammarPanel(BuildContext context) {
    final colors = context.vocaColors;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPanelHeader(
            context: context,
            title: context.t('grammar.mode', null, 'Grammar Mode'),
            icon: Icons.auto_awesome_rounded,
          ),
          _buildOptionRow(
            context: context,
            label: context.t('player.off', null, 'Off'),
            isSelected: false,
            leading: Icon(Icons.block_rounded, size: 18, color: colors.textMuted),
            onTap: () => setState(() => _currentView = 'main'),
          ),
          _buildOptionRow(
            context: context,
            label: context.t('common.on', null, 'On (Highlight Patterns)'),
            isSelected: true,
            leading: Icon(Icons.auto_awesome_rounded, size: 18, color: colors.colorGrammar),
            onTap: () => setState(() => _currentView = 'main'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ==========================================
  // 7. SLEEP TIMER PANEL
  // ==========================================
  Widget _buildSleepTimerPanel(BuildContext context) {
    const timerMinutes = ['5', '10', '15', '30', '45', '60'];
    final currentOption = widget.controller.sleepTimerOption.value;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPanelHeader(
            context: context,
            title: context.t('player.sleepTimer', null, 'Sleep timer'),
            icon: Icons.timer_outlined,
          ),
          _buildOptionRow(
            context: context,
            label: context.t('player.off', null, 'Off'),
            isSelected: currentOption == 'off',
            onTap: () {
              widget.controller.clearSleepTimer();
              setState(() => _currentView = 'main');
            },
          ),
          for (final m in timerMinutes)
            _buildOptionRow(
              context: context,
              label: '$m minutes',
              isSelected: currentOption == m,
              onTap: () {
                widget.controller.setSleepTimer(
                  m,
                  onTimerEnd: () => widget.ytController.pauseVideo(),
                );
                setState(() => _currentView = 'main');
              },
            ),
          _buildOptionRow(
            context: context,
            label: context.t('player.sleepTimerEndOfVideo', null, 'End of video'),
            isSelected: currentOption == 'end',
            onTap: () {
              widget.controller.setSleepTimer(
                'end',
                onTimerEnd: () => widget.ytController.pauseVideo(),
              );
              setState(() => _currentView = 'main');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionRow({
    required BuildContext context,
    required String label,
    required bool isSelected,
    bool isDisabled = false,
    Widget? leading,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final colors = context.vocaColors;
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        color: isSelected ? colors.accentPrimarySoft.withValues(alpha: 0.08) : Colors.transparent,
        child: Row(
          children: [
            if (leading != null) ...[
              leading,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isDisabled
                      ? colors.textMuted
                      : (isSelected ? colors.accentPrimary : colors.textPrimary),
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 8),
            ],
            if (isSelected)
              Icon(Icons.check_rounded, size: 20, color: colors.accentPrimary),
          ],
        ),
      ),
    );
  }
}
