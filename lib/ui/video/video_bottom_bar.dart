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
///   - Fullscreen button is explicitly REMOVED per user request.
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
  final Color? accentColor;

  // Callbacks
  final VoidCallback? onPlayPause;
  final VoidCallback? onToggleSubtitles;
  final VoidCallback? onToggleDualSubtitles;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onToggleMiniplayer;

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
    this.accentColor,
    this.onPlayPause,
    this.onToggleSubtitles,
    this.onToggleDualSubtitles,
    this.onOpenSettings,
    this.onToggleMiniplayer,
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
          // RIGHT CONTROLS
          // ==========================================
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. CC Subtitles toggle button
              _buildSubtitlesButton(context, effectiveAccent),

              // 2. Dual Subtitles toggle button (CJK languages)
              if (showDualSubsButton) ...[
                const SizedBox(width: 4),
                _buildDualSubsButton(context, effectiveAccent),
              ],

              const SizedBox(width: 4),

              // 3. Settings gear button
              _buildControlButton(
                icon: Icons.settings_outlined,
                iconSize: 18,
                tooltip: context.t('player.settings', null, 'Settings'),
                onTap: onOpenSettings,
              ),

              const SizedBox(width: 4),

              // 4. Miniplayer toggle button
              if (onToggleMiniplayer != null)
                _buildControlButton(
                  icon: Icons.picture_in_picture_alt_rounded,
                  iconSize: 18,
                  tooltip: context.t('player.miniplayer', null, 'Miniplayer'),
                  onTap: onToggleMiniplayer,
                ),
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
                color: Colors.white.withOpacity(0.40),
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
              color: Colors.white.withOpacity(0.65),
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

  /// Subtitles CC button with active indicator bar and AI icon if AI subtitle
  Widget _buildSubtitlesButton(BuildContext context, Color accent) {
    final indicatorColor =
        isAISubtitle ? const Color(0xFF818CF8) : accent;

    return Tooltip(
      message: isAISubtitle
          ? context.t('subtitle.aiCaptions', null, 'AI Captions')
          : context.t('subtitle.title', null, 'Subtitles'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggleSubtitles,
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  isAISubtitle
                      ? Icons.auto_awesome_rounded
                      : Icons.closed_caption_rounded,
                  size: 19,
                  color: subtitlesVisible
                      ? Colors.white
                      : Colors.white.withOpacity(0.65),
                  shadows: const [
                    Shadow(
                      color: Color.fromRGBO(0, 0, 0, 0.85),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                // Active indicator bar at bottom
                Positioned(
                  bottom: 5,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: subtitlesVisible ? 1.0 : 0.0,
                    child: Container(
                      width: 12,
                      height: 2,
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: [
                          BoxShadow(
                            color: indicatorColor.withOpacity(0.6),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dual subtitles toggle button with active indicator bar
  Widget _buildDualSubsButton(BuildContext context, Color accent) {
    return Tooltip(
      message: context.t('subtitle.dualSubtitles', null, 'Dual Subtitles'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggleDualSubtitles,
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 18,
                  color: showDualSubtitles
                      ? Colors.white
                      : Colors.white.withOpacity(0.65),
                  shadows: const [
                    Shadow(
                      color: Color.fromRGBO(0, 0, 0, 0.85),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                // Active indicator bar at bottom
                Positioned(
                  bottom: 5,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: showDualSubtitles ? 1.0 : 0.0,
                    child: Container(
                      width: 12,
                      height: 2,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.6),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required double iconSize,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: iconSize,
              color: Colors.white.withOpacity(0.9),
              shadows: const [
                Shadow(
                  color: Color.fromRGBO(0, 0, 0, 0.85),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
