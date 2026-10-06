// lib/ui/video/center_controls.dart

import 'package:flutter/material.dart';
import '../../services/i18n_service.dart';
import '../../utils/video_format_utils.dart';

export '../../utils/video_format_utils.dart' show formatVideoTime;

/// CenterControls Widget
///
/// Ported from lingua-tube's CenterControlsComponent.
/// Handles unified play/pause/buffering/replay states, playlist navigation,
/// play/pause feedback pops, volume feedback pops, and gesture seek preview HUD.
class CenterControls extends StatefulWidget {
  final bool isReady;
  final bool isPlaying;
  final bool isBuffering;
  final bool isEnded;
  final bool areControlsVisible;
  final bool hasPlaylist;
  final bool canPlayPrev;
  final bool canPlayNext;

  // Feedback overlays
  final bool playPauseFeedback;
  final IconData? playPauseFeedbackIcon;
  final bool volumeFeedback;
  final IconData? volumeFeedbackIcon;
  final bool gestureSeekActive;
  final double gestureSeekTime;
  final double currentTime;

  // Callbacks
  final VoidCallback? onPlayPause;
  final VoidCallback? onReplay;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const CenterControls({
    super.key,
    this.isReady = true,
    required this.isPlaying,
    this.isBuffering = false,
    this.isEnded = false,
    this.areControlsVisible = true,
    this.hasPlaylist = false,
    this.canPlayPrev = true,
    this.canPlayNext = true,
    this.playPauseFeedback = false,
    this.playPauseFeedbackIcon,
    this.volumeFeedback = false,
    this.volumeFeedbackIcon,
    this.gestureSeekActive = false,
    this.gestureSeekTime = 0.0,
    this.currentTime = 0.0,
    this.onPlayPause,
    this.onReplay,
    this.onPrev,
    this.onNext,
  });

  @override
  State<CenterControls> createState() => _CenterControlsState();
}

class _CenterControlsState extends State<CenterControls>
    with TickerProviderStateMixin {
  late final AnimationController _playPauseAnimController;
  late final AnimationController _volumeAnimController;

  @override
  void initState() {
    super.initState();
    _playPauseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _volumeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    if (widget.playPauseFeedback) {
      _playPauseAnimController.forward(from: 0.0);
    }
    if (widget.volumeFeedback) {
      _volumeAnimController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant CenterControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playPauseFeedback && !oldWidget.playPauseFeedback) {
      _playPauseAnimController.forward(from: 0.0);
    }
    if (widget.volumeFeedback && !oldWidget.volumeFeedback) {
      _volumeAnimController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _playPauseAnimController.dispose();
    _volumeAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Play/Pause Feedback Pop (YouTube style pop HUD)
          if (widget.playPauseFeedback)
            _buildCenterFeedbackPop(
              controller: _playPauseAnimController,
              icon: widget.playPauseFeedbackIcon ??
                  (widget.isPlaying
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded),
            ),

          // 2. Volume Feedback Pop
          if (widget.volumeFeedback)
            _buildCenterFeedbackPop(
              controller: _volumeAnimController,
              icon: widget.volumeFeedbackIcon ?? Icons.volume_up_rounded,
            ),

          // 3. Gesture Seek Preview HUD
          if (widget.gestureSeekActive) _buildGestureSeekPreview(),

          // 4. Main Button Group (Play/Pause/Buffering/Prev/Next)
          if (widget.isReady && !widget.isEnded)
            AnimatedOpacity(
              opacity: widget.areControlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: IgnorePointer(
                ignoring: !widget.areControlsVisible,
                child: _buildMainButtonGroup(),
              ),
            ),

          // 5. Replay Button Group (Ended State - always visible)
          if (widget.isEnded) _buildEndedButtonGroup(),
        ],
      ),
    );
  }

  /// 44px Icon Feedback Pop with 350ms keyframe animation (0% -> 30% -> 70% -> 100%)
  Widget _buildCenterFeedbackPop({
    required AnimationController controller,
    required IconData icon,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        // Keyframes:
        // 0% - 30%: opacity 0 -> 1, scale 0.92 -> 1.0
        // 30% - 70%: opacity 1.0, scale 1.0
        // 70% - 100%: opacity 1.0 -> 0, scale 1.0 -> 1.06
        double opacity;
        double scale;
        if (t < 0.3) {
          final progress = t / 0.3;
          opacity = progress;
          scale = 0.92 + (1.0 - 0.92) * progress;
        } else if (t < 0.7) {
          opacity = 1.0;
          scale = 1.0;
        } else {
          final progress = (t - 0.7) / 0.3;
          opacity = 1.0 - progress;
          scale = 1.0 + 0.06 * progress;
        }

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(0, 0, 0, 0.65),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 44,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Gesture Seek Preview HUD showing large formatted seek time + relative delta (+0:30 / -0:15)
  Widget _buildGestureSeekPreview() {
    final seekDelta = widget.gestureSeekTime - widget.currentTime;
    final isPositive = seekDelta >= 0;
    final formattedDelta = formatVideoTime(seekDelta.abs());
    final deltaSign = isPositive ? '+' : '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.85),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large formatted seek time
          Text(
            formatVideoTime(widget.gestureSeekTime),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          // Relative delta (+0:30 or -0:15)
          Text(
            '$deltaSign$formattedDelta',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  /// Main Button Group: [Prev] [Play/Pause/Buffer] [Next]
  Widget _buildMainButtonGroup() {
    final isBufferingAndPlaying = widget.isBuffering && widget.isPlaying;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Previous video button (Playlist only)
        if (widget.hasPlaylist) ...[
          _buildNavButton(
            icon: Icons.skip_previous_rounded,
            tooltip: context.t('player.previousVideo', null, 'Previous video'),
            isEnabled: widget.canPlayPrev,
            onTap: widget.onPrev,
          ),
          const SizedBox(width: 24),
        ],

        // Unified Big Play / Pause / Buffering button with tactile spring press & AnimatedSwitcher icon
        _AnimatedPressButton(
          onTap: widget.onPlayPause,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 0, 0, 0.6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: isBufferingAndPlaying
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: widget.isPlaying
                          ? const Icon(
                              Icons.pause_rounded,
                              key: ValueKey('pause_icon'),
                              size: 44,
                              color: Colors.white,
                            )
                          : const Padding(
                              key: ValueKey('play_icon'),
                              padding: EdgeInsets.only(left: 3.0),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 44,
                                color: Colors.white,
                              ),
                            ),
                    ),
            ),
          ),
        ),

        // Next video button (Playlist only)
        if (widget.hasPlaylist) ...[
          const SizedBox(width: 24),
          _buildNavButton(
            icon: Icons.skip_next_rounded,
            tooltip: context.t('player.nextVideo', null, 'Next video'),
            isEnabled: widget.canPlayNext,
            onTap: widget.onNext,
          ),
        ],
      ],
    );
  }

  /// Ended Button Group: Replay button (with optional playlist navigation)
  Widget _buildEndedButtonGroup() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.hasPlaylist) ...[
          _buildNavButton(
            icon: Icons.skip_previous_rounded,
            tooltip: context.t('player.previousVideo', null, 'Previous video'),
            isEnabled: widget.canPlayPrev,
            onTap: widget.onPrev,
          ),
          const SizedBox(width: 24),
        ],

        // Replay Button with tactile press
        _AnimatedPressButton(
          onTap: widget.onReplay ?? widget.onPlayPause,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 0, 0, 0.75),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.replay_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),
          ),
        ),

        if (widget.hasPlaylist) ...[
          const SizedBox(width: 24),
          _buildNavButton(
            icon: Icons.skip_next_rounded,
            tooltip: context.t('player.nextVideo', null, 'Next video'),
            isEnabled: widget.canPlayNext,
            onTap: widget.onNext,
          ),
        ],
      ],
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String tooltip,
    required bool isEnabled,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: _AnimatedPressButton(
        onTap: isEnabled ? onTap : null,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isEnabled
                ? const Color.fromRGBO(0, 0, 0, 0.6)
                : const Color.fromRGBO(0, 0, 0, 0.45),
            shape: BoxShape.circle,
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 24,
              color: isEnabled
                  ? Colors.white
                  : Colors.white.withOpacity(0.35),
            ),
          ),
        ),
      ),
    );
  }
}

/// Springy tactile press scale micro-interaction wrapper
class _AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _AnimatedPressButton({
    required this.child,
    this.onTap,
  });

  @override
  State<_AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<_AnimatedPressButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (highlighted) {
            if (_isPressed != highlighted) {
              setState(() => _isPressed = highlighted);
            }
          },
          customBorder: const CircleBorder(),
          child: widget.child,
        ),
      ),
    );
  }
}
