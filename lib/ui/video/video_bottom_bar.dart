// lib/ui/video/video_bottom_bar.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../utils/video_format_utils.dart';

export '../../utils/video_format_utils.dart' show formatVideoTime;

/// VideoBottomBar Widget
///
/// Ported from lingua-tube's VideoBottomBarComponent.
/// Features:
/// - Left controls:
///   - Play/pause toggle button (replay icon if ended)
///   - Time display: M:SS / M:SS (tabular figures, current in bright white,
///     separator in 40% white, total in 65% white)
/// - Right controls:
///   - CC Subtitles toggle button (with active indicator bar, AI icon if AI subtitle)
///   - Dual Subtitles toggle button (languages icon with active indicator bar)
///   - Settings gear button (opens settings sheet)
///   - Miniplayer toggle button (picture-in-picture)
///   - Fullscreen button (toggles fullscreen landscape / exit)
class VideoBottomBar extends StatelessWidget {
  // Playback state
  final bool isPlaying;
  final bool isEnded;
  final double currentTime;
  final double duration;
  final String? formattedCurrentTime;
  final String? formattedDuration;

  // Features state
  final bool showPlayPause;
  final bool subtitlesVisible;
  final bool isAISubtitle;
  final bool showDualSubtitles;
  final bool isCJKLanguage;
  final bool showDualSubtitlesToggle;
  final bool showSubtitlesToggle;
  final bool isFullscreen;
  final Color? accentColor;

  // Callbacks
  final VoidCallback? onPlayPause;
  final VoidCallback? onToggleSubtitles;
  final VoidCallback? onToggleDualSubtitles;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onToggleMiniplayer;
  final VoidCallback? onToggleFullscreen;

  const VideoBottomBar({
    super.key,
    required this.isPlaying,
    this.isEnded = false,
    this.currentTime = 0.0,
    this.duration = 0.0,
    this.formattedCurrentTime,
    this.formattedDuration,
    this.showPlayPause = true,
    this.subtitlesVisible = true,
    this.isAISubtitle = false,
    this.showDualSubtitles = false,
    this.isCJKLanguage = false,
    this.showDualSubtitlesToggle = true,
    this.showSubtitlesToggle = true,
    this.isFullscreen = false,
    this.accentColor,
    this.onPlayPause,
    this.onToggleSubtitles,
    this.onToggleDualSubtitles,
    this.onOpenSettings,
    this.onToggleMiniplayer,
    this.onToggleFullscreen,
  });

  String get _effectiveCurrentTime =>
      formattedCurrentTime ?? formatVideoTime(currentTime);

  String get _effectiveDuration =>
      formattedDuration ?? formatVideoTime(duration);

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? context.vocaColors.accentPrimary;

    final showDualSubsButton = showDualSubtitlesToggle && isCJKLanguage;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ==========================================
          // LEFT CONTROLS
          // ==========================================
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Play / Pause / Replay toggle button (desktop or when enabled)
              if (showPlayPause && onPlayPause != null) ...[
                _buildControlButton(
                  icon: isEnded
                      ? Icons.replay_rounded
                      : (isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  iconSize: 20,
                  tooltip: isEnded
                      ? context.t('player.replay', null, 'Replay')
                      : (isPlaying
                          ? context.t('player.pause', null, 'Pause')
                          : context.t('player.play', null, 'Play')),
                  onTap: onPlayPause,
                ),
                const SizedBox(width: 4),
              ],

              // 2. Time Display: M:SS / M:SS
              _buildTimeDisplay(),
            ],
          ),

          const Spacer(),

          // ==========================================
          // RIGHT CONTROLS (1:1 with Pic 3 and lingua-tube)
          // ==========================================
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Dual Subtitles toggle button (CJK languages)
              if (showDualSubsButton) ...[
                _buildDualSubsButton(context, effectiveAccent),
                const SizedBox(width: 4),
              ],

              // 2. Fullscreen toggle button
              if (onToggleFullscreen != null) ...[
                _buildControlButton(
                  icon: isFullscreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  iconSize: 22,
                  tooltip: isFullscreen
                      ? context.t('player.exitFullscreen', null, 'Exit fullscreen')
                      : context.t('player.fullscreen', null, 'Fullscreen'),
                  onTap: onToggleFullscreen,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Time display: M:SS / M:SS (tabular figures, current in bright white,
  /// separator in 40% white, total in 65% white)
  Widget _buildTimeDisplay() {
    return Container(
      height: 36,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Current Time in bright white
          Text(
            _effectiveCurrentTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: 0.1,
              shadows: [
                Shadow(
                  color: Color.fromRGBO(0, 0, 0, 0.85),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),

          // Separator in 40% white
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              '/',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.40),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                shadows: const [
                  Shadow(
                    color: Color.fromRGBO(0, 0, 0, 0.85),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),

          // Total Duration in 65% white
          Text(
            _effectiveDuration,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 0.1,
              shadows: const [
                Shadow(
                  color: Color.fromRGBO(0, 0, 0, 0.85),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dual subtitles toggle button
  Widget _buildDualSubsButton(BuildContext context, Color accent) {
    return IconButton(
      tooltip: context.t('subtitle.dualSubtitles', null, 'Dual Subtitles'),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(
        Icons.translate_rounded,
        size: 19,
        color: showDualSubtitles
            ? accent
            : Colors.white.withValues(alpha: 0.65),
        shadows: showDualSubtitles
            ? [
                Shadow(
                  color: accent.withValues(alpha: 0.6),
                  blurRadius: 4,
                ),
              ]
            : const [
                Shadow(
                  color: Color.fromRGBO(0, 0, 0, 0.85),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      onPressed: onToggleDualSubtitles,
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required double iconSize,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return IconButton(
      tooltip: tooltip,
      iconSize: iconSize,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(
        icon,
        size: iconSize,
        color: Colors.white.withValues(alpha: 0.9),
        shadows: const [
          Shadow(
            color: Color.fromRGBO(0, 0, 0, 0.85),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      onPressed: onTap,
    );
  }
}
