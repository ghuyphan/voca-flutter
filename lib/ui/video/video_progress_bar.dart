// lib/ui/video/video_progress_bar.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../utils/video_format_utils.dart';

export '../../utils/video_format_utils.dart' show formatVideoTime;

/// VideoProgressBar Widget
///
/// Ported from lingua-tube's ProgressBarComponent.
/// Features:
/// - Expandable hit area for effortless touch scrubbing (min height 24px/36px)
/// - Base track (30% white)
/// - Buffered track (35% white)
/// - Played progress track (accentPrimary)
/// - Draggable circular thumb handle with white border
/// - Dragging and hover tooltip showing formatted seek time
/// - Callbacks for onSeekStarted, onSeekUpdate, onSeekEnded
class VideoProgressBar extends StatefulWidget {
  final double currentTime;
  final double duration;
  final double bufferedFraction; // 0.0 to 1.0
  final Color? accentColor;
  final double hitAreaHeight;
  final double baseTrackHeight;
  final double activeTrackHeight;
  final double handleSize;
  final double activeHandleSize;
  final bool showHandle;

  final VoidCallback? onSeekStarted;
  final ValueChanged<double>? onSeekUpdate;
  final ValueChanged<double>? onSeekEnded;

  const VideoProgressBar({
    super.key,
    required this.currentTime,
    required this.duration,
    this.bufferedFraction = 0.0,
    this.accentColor,
    this.hitAreaHeight = 36.0,
    this.baseTrackHeight = 4.0,
    this.activeTrackHeight = 6.0,
    this.handleSize = 14.0,
    this.activeHandleSize = 16.0,
    this.showHandle = true,
    this.onSeekStarted,
    this.onSeekUpdate,
    this.onSeekEnded,
  });

  @override
  State<VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  bool _isDragging = false;
  double _dragTime = 0.0;
  bool _isHovering = false;
  double _hoverPosition = 0.0;
  double _hoverTime = 0.0;

  double get _displayTime => _isDragging ? _dragTime : widget.currentTime;

  double get _progressFraction {
    if (widget.duration <= 0) return 0.0;
    return (_displayTime / widget.duration).clamp(0.0, 1.0);
  }

  double get _bufferedFractionClamped {
    return widget.bufferedFraction.clamp(0.0, 1.0);
  }

  void _handleDragStart(DragStartDetails details, double trackWidth) {
    if (widget.duration <= 0 || trackWidth <= 0) return;
    final localX = details.localPosition.dx.clamp(0.0, trackWidth);
    final ratio = localX / trackWidth;
    final time = (ratio * widget.duration).clamp(0.0, widget.duration);

    setState(() {
      _isDragging = true;
      _dragTime = time;
    });

    widget.onSeekStarted?.call();
    widget.onSeekUpdate?.call(time);
  }

  void _handleDragUpdate(DragUpdateDetails details, double trackWidth) {
    if (widget.duration <= 0 || trackWidth <= 0) return;
    final localX = details.localPosition.dx.clamp(0.0, trackWidth);
    final ratio = localX / trackWidth;
    final time = (ratio * widget.duration).clamp(0.0, widget.duration);

    setState(() {
      _dragTime = time;
    });

    widget.onSeekUpdate?.call(time);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    final finalTime = _dragTime;
    setState(() {
      _isDragging = false;
    });
    widget.onSeekEnded?.call(finalTime);
  }

  void _handleDragCancel() {
    if (!_isDragging) return;
    final finalTime = _dragTime;
    setState(() {
      _isDragging = false;
    });
    widget.onSeekEnded?.call(finalTime);
  }

  void _handleTapDown(TapDownDetails details, double trackWidth) {
    if (widget.duration <= 0 || trackWidth <= 0) return;
    final localX = details.localPosition.dx.clamp(0.0, trackWidth);
    final ratio = localX / trackWidth;
    final time = (ratio * widget.duration).clamp(0.0, widget.duration);

    setState(() {
      _isDragging = true;
      _dragTime = time;
    });

    widget.onSeekStarted?.call();
    widget.onSeekUpdate?.call(time);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isDragging) return;
    final finalTime = _dragTime;
    setState(() {
      _isDragging = false;
    });
    widget.onSeekEnded?.call(finalTime);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAccent =
        widget.accentColor ?? context.vocaColors.accentPrimary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final isActive = _isDragging || _isHovering;
        final currentTrackHeight =
            isActive ? widget.activeTrackHeight : widget.baseTrackHeight;
        final currentHandleSize =
            isActive ? widget.activeHandleSize : widget.handleSize;

        // Position handle clamped inside bounds so it never clips at 0% or 100%
        final handleRadius = currentHandleSize / 2.0;
        final handleCenterX = (totalWidth > currentHandleSize)
            ? handleRadius +
                (totalWidth - currentHandleSize) * _progressFraction
            : totalWidth * _progressFraction;

        // Position of tooltip
        final tooltipCenterX = _isDragging
            ? handleCenterX
            : _hoverPosition.clamp(handleRadius, totalWidth - handleRadius);
        final tooltipTime = _isDragging ? _dragTime : _hoverTime;

        return MouseRegion(
          onHover: (event) {
            if (widget.duration <= 0 || totalWidth <= 0) return;
            final localX = event.localPosition.dx.clamp(0.0, totalWidth);
            final ratio = localX / totalWidth;
            final time = (ratio * widget.duration).clamp(0.0, widget.duration);
            setState(() {
              _isHovering = true;
              _hoverPosition = localX;
              _hoverTime = time;
            });
          },
          onExit: (_) {
            if (_isHovering) {
              setState(() {
                _isHovering = false;
              });
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => _handleDragStart(d, totalWidth),
            onHorizontalDragUpdate: (d) => _handleDragUpdate(d, totalWidth),
            onHorizontalDragEnd: _handleDragEnd,
            onHorizontalDragCancel: _handleDragCancel,
            onTapDown: (d) => _handleTapDown(d, totalWidth),
            onTapUp: _handleTapUp,
            child: SizedBox(
              height: widget.hitAreaHeight,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // 1. Base Track (30% white)
                  Center(
                    child: Container(
                      height: currentTrackHeight,
                      width: totalWidth,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.30),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.4),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Buffered Track (35% white)
                  Center(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: currentTrackHeight,
                        width: (totalWidth * _bufferedFractionClamped)
                            .clamp(0.0, totalWidth),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),

                  // 3. Played Progress Track (accentPrimary)
                  Center(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: currentTrackHeight,
                        width: (totalWidth * _progressFraction)
                            .clamp(0.0, totalWidth),
                        decoration: BoxDecoration(
                          color: effectiveAccent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),

                  // 4. Draggable Thumb Handle
                  if (widget.showHandle)
                    Positioned(
                      left: handleCenterX - handleRadius,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          width: currentHandleSize,
                          height: currentHandleSize,
                          decoration: BoxDecoration(
                            color: effectiveAccent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                              BoxShadow(
                                color: effectiveAccent.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 5. Seek Preview Tooltip (above progress bar)
                  if (_isDragging || _isHovering)
                    Positioned(
                      bottom: widget.hitAreaHeight * 0.85,
                      left: (tooltipCenterX - 28.0)
                          .clamp(4.0, (totalWidth - 56.0).clamp(4.0, double.infinity)),
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(0, 0, 0, 0.85),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            formatVideoTime(tooltipTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
