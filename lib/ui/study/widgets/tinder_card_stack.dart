// lib/ui/study/widgets/tinder_card_stack.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../models/voca_models.dart';
import '../../../services/haptic_service.dart';
import '../../../services/srs_service.dart';
import 'flashcard_face.dart';

/// Controller interface to programmatically trigger swipe or flip from bottom dock
class TinderStackController {
  _TinderCardStackState? _state;

  void _attach(_TinderCardStackState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void swipeLeft() => _state?.programmaticSwipe(SRSReviewRating.again);
  void swipeRight() => _state?.programmaticSwipe(SRSReviewRating.good);
  void swipeUp() => _state?.programmaticSwipe(SRSReviewRating.easy);
  void swipeDown() => _state?.programmaticSwipe(SRSReviewRating.hard);
}

/// High-performance, physics-based multi-card swiper with natural thumb pivot rotation,
/// RepaintBoundary GPU layer caching, and seamless next-card promotion.
class TinderCardStack extends StatefulWidget {
  final Flashcard currentCard;
  final Flashcard? nextCard;
  final Flashcard? cardAfterNext;
  final int cardIndex;
  final bool isRevealed;
  final bool isReadingPeeked;
  final ValueChanged<SRSReviewRating> onSwipe;
  final VoidCallback onToggleFlip;
  final VoidCallback onTogglePeekReading;
  final String againInterval;
  final String? hardInterval;
  final String goodInterval;
  final String? easyInterval;
  final TinderStackController? controller;

  const TinderCardStack({
    super.key,
    required this.currentCard,
    this.nextCard,
    this.cardAfterNext,
    this.cardIndex = 0,
    required this.isRevealed,
    required this.isReadingPeeked,
    required this.onSwipe,
    required this.onToggleFlip,
    required this.onTogglePeekReading,
    this.againInterval = '<1 min',
    this.hardInterval,
    this.goodInterval = '1 d',
    this.easyInterval,
    this.controller,
  });

  @override
  State<TinderCardStack> createState() => _TinderCardStackState();
}

class _TinderCardStackState extends State<TinderCardStack>
    with TickerProviderStateMixin {
  // Zero-rebuild drag offset notifier for 120fps gesture tracking
  final ValueNotifier<Offset> _dragOffsetNotifier = ValueNotifier<Offset>(Offset.zero);
  bool _isDragging = false;
  bool _hasHapticTriggered = false;
  DateTime? _panStartTime;

  // Animation controller for drag release snap-back & programmatic swipe
  late final AnimationController _flightController;
  Animation<Offset>? _flightOffsetAnimation;
  Animation<double>? _flightRotationAnimation;

  // 3D perspective flip controller
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  // Merged listenable created once to avoid per-build allocation
  late final Listenable _combinedAnimation;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);

    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeOutCubic),
    );

    if (widget.isRevealed) {
      _flipController.value = 1.0;
    }

    _combinedAnimation = Listenable.merge([
      _dragOffsetNotifier,
      _flightController,
      _flipController,
    ]);
  }

  @override
  void didUpdateWidget(covariant TinderCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
    }
    widget.controller?._attach(this);

    if (widget.currentCard.id != oldWidget.currentCard.id ||
        widget.cardIndex != oldWidget.cardIndex) {
      _isDragging = false;
      _hasHapticTriggered = false;
      _flightController.reset();
      _flipController.reset();
      if (widget.isRevealed) {
        _flipController.value = 1.0;
      }
      _dragOffsetNotifier.value = Offset.zero;
    } else if (widget.isRevealed != oldWidget.isRevealed) {
      if (widget.isRevealed) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _dragOffsetNotifier.dispose();
    _flightController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void toggleFlip() {
    if (_flightController.isAnimating) return;
    HapticService.selection();
    widget.onToggleFlip();
  }

  void programmaticSwipe(SRSReviewRating rating) {
    if (_flightController.isAnimating) return;
    HapticService.medium();

    final size = MediaQuery.sizeOf(context);
    final startOffset = _dragOffsetNotifier.value;
    final endOffset = switch (rating) {
      SRSReviewRating.again => Offset(-size.width * 1.2, 20),
      SRSReviewRating.good => Offset(size.width * 1.2, 20),
      SRSReviewRating.easy => Offset(0, -size.height * 0.85),
      SRSReviewRating.hard => Offset(0, size.height * 0.85),
    };

    final endRotation = switch (rating) {
      SRSReviewRating.again => -0.28,
      SRSReviewRating.good => 0.28,
      SRSReviewRating.easy => 0.0,
      SRSReviewRating.hard => 0.0,
    };

    _flightController.duration = const Duration(milliseconds: 250);

    _flightOffsetAnimation = Tween<Offset>(
      begin: startOffset,
      end: endOffset,
    ).animate(CurvedAnimation(parent: _flightController, curve: Curves.easeOutCubic));

    _flightRotationAnimation = Tween<double>(
      begin: _calculateRotation(startOffset.dx, size.width),
      end: endRotation,
    ).animate(CurvedAnimation(parent: _flightController, curve: Curves.easeOutCubic));

    _flightController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      // Keep _flightController at 1.0 (off-screen) until didUpdateWidget swaps in the new card
      // on the next frame, preventing any 1-frame snap-back flash of the old card.
      widget.onSwipe(rating);
    });
  }

  double _calculateRotation(double dx, double screenWidth) {
    return (dx / screenWidth) * 0.45;
  }

  double _calculateProgressFromOffset(Offset offset) {
    final horizontalRatio = (offset.dx.abs() / 100.0).clamp(0.0, 1.0);
    final verticalRatio = (offset.dy.abs() / 100.0).clamp(0.0, 1.0);
    return math.max(horizontalRatio, verticalRatio);
  }

  void _onPanStart(DragStartDetails details) {
    if (_flightController.isAnimating || _flightController.value > 0.0) return;
    _isDragging = true;
    _hasHapticTriggered = false;
    _panStartTime = DateTime.now();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_flightController.isAnimating || _flightController.value > 0.0) return;
    final nextOffset = _dragOffsetNotifier.value + details.delta;
    _dragOffsetNotifier.value = nextOffset;

    final dist = math.max(nextOffset.dx.abs(), nextOffset.dy.abs());
    if (dist > 65 && !_hasHapticTriggered) {
      _hasHapticTriggered = true;
      HapticService.light();
    } else if (dist <= 65 && _hasHapticTriggered) {
      _hasHapticTriggered = false;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_flightController.isAnimating || _flightController.value > 0.0) return;
    final size = MediaQuery.sizeOf(context);
    final velocity = details.velocity.pixelsPerSecond;
    final dragOffset = _dragOffsetNotifier.value;
    final elapsedMs = _panStartTime != null
        ? DateTime.now().difference(_panStartTime!).inMilliseconds
        : 999;

    // Forgiving tap-to-flip if user made a quick thumb tap with slight finger movement
    if (dragOffset.distance < 24.0 && velocity.distance < 350.0) {
      _isDragging = false;
      _dragOffsetNotifier.value = Offset.zero;
      if (elapsedMs < 260 && dragOffset.distance > 2.0) {
        toggleFlip();
      }
      return;
    }

    SRSReviewRating? rating;
    Offset targetOffset = Offset.zero;
    double targetRotation = 0.0;

    // Dominant axis multi-directional swipe recognition
    final isHorizontalDominant = dragOffset.dx.abs() >= dragOffset.dy.abs();
    if (isHorizontalDominant) {
      if (dragOffset.dx > 65 || velocity.dx > 380) {
        rating = SRSReviewRating.good;
        targetOffset = Offset(size.width * 1.25, dragOffset.dy + velocity.dy * 0.06);
        targetRotation = 0.30;
      } else if (dragOffset.dx < -65 || velocity.dx < -380) {
        rating = SRSReviewRating.again;
        targetOffset = Offset(-size.width * 1.25, dragOffset.dy + velocity.dy * 0.06);
        targetRotation = -0.30;
      }
    } else {
      if (dragOffset.dy < -65 || velocity.dy < -380) {
        rating = SRSReviewRating.easy;
        targetOffset = Offset(dragOffset.dx, -size.height * 0.9);
        targetRotation = 0.0;
      } else if (dragOffset.dy > 65 || velocity.dy > 380) {
        rating = SRSReviewRating.hard;
        targetOffset = Offset(dragOffset.dx, size.height * 0.9);
        targetRotation = 0.0;
      }
    }

    if (rating != null) {
      HapticService.medium();
      _flightController.duration = const Duration(milliseconds: 210);
      _flightOffsetAnimation = Tween<Offset>(
        begin: dragOffset,
        end: targetOffset,
      ).animate(CurvedAnimation(parent: _flightController, curve: Curves.easeOutCubic));

      _flightRotationAnimation = Tween<double>(
        begin: _calculateRotation(dragOffset.dx, size.width),
        end: targetRotation,
      ).animate(CurvedAnimation(parent: _flightController, curve: Curves.easeOutCubic));

      _flightController.forward(from: 0.0).then((_) {
        if (!mounted) return;
        // Keep _flightController at 1.0 until didUpdateWidget swaps in the new card
        widget.onSwipe(rating!);
      });
    } else {
      // Smooth spring snap-back to center
      _flightController.duration = const Duration(milliseconds: 240);
      _flightOffsetAnimation = Tween<Offset>(
        begin: dragOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _flightController, curve: Curves.easeOutBack));

      _flightRotationAnimation = Tween<double>(
        begin: _calculateRotation(dragOffset.dx, size.width),
        end: 0.0,
      ).animate(CurvedAnimation(parent: _flightController, curve: Curves.easeOutBack));

      _flightController.forward(from: 0.0).then((_) {
        if (!mounted) return;
        _isDragging = false;
        _flightController.reset();
        _dragOffsetNotifier.value = Offset.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final colors = context.vocaColors;

    // Pre-build and cache GPU RepaintBoundary layers outside AnimatedBuilder
    // so 60-120fps drag/flight frames never rebuild or rasterize FlashcardFace.
    final frontFace = RepaintBoundary(
      child: FlashcardFace(
        key: ValueKey('front_${widget.currentCard.id}_${widget.isReadingPeeked}'),
        card: widget.currentCard,
        isBack: false,
        isReadingPeeked: widget.isReadingPeeked,
        onTogglePeekReading: widget.onTogglePeekReading,
        againInterval: widget.againInterval,
        goodInterval: widget.goodInterval,
      ),
    );

    final backFace = RepaintBoundary(
      child: FlashcardFace(
        key: ValueKey('back_${widget.currentCard.id}'),
        card: widget.currentCard,
        isBack: true,
        againInterval: widget.againInterval,
        goodInterval: widget.goodInterval,
      ),
    );

    final nextCardLayer = widget.nextCard != null
        ? RepaintBoundary(
            child: IgnorePointer(
              child: FlashcardFace(
                key: ValueKey('next_${widget.nextCard!.id}'),
                card: widget.nextCard!,
                isBack: false,
                againInterval: widget.againInterval,
                goodInterval: widget.goodInterval,
              ),
            ),
          )
        : null;

    final thirdCardShell = widget.cardAfterNext != null
        ? RepaintBoundary(
            child: IgnorePointer(
              child: _buildDeckCardShell(colors: colors),
            ),
          )
        : null;

    return AnimatedBuilder(
      animation: _combinedAnimation,
      builder: (context, _) {
        final isFlightActive = _flightController.isAnimating || _flightController.value > 0.0;
        final currentOffset = isFlightActive && _flightOffsetAnimation != null
            ? _flightOffsetAnimation!.value
            : _dragOffsetNotifier.value;

        final currentRotation = isFlightActive && _flightRotationAnimation != null
            ? _flightRotationAnimation!.value
            : _calculateRotation(currentOffset.dx, size.width);

        final progress = (_isDragging || isFlightActive)
            ? _calculateProgressFromOffset(currentOffset)
            : 0.0;

        final dx = currentOffset.dx;
        final dy = currentOffset.dy;
        final isHorizontal = dx.abs() >= dy.abs();

        // Normalized progress for 4 directions
        final goodProgress = (isHorizontal && dx > 0 ? (dx / 70.0) : 0.0).clamp(0.0, 1.0);
        final againProgress = (isHorizontal && dx < 0 ? (-dx / 70.0) : 0.0).clamp(0.0, 1.0);
        final hardProgress = (!isHorizontal && dy > 0 ? (dy / 70.0) : 0.0).clamp(0.0, 1.0);
        final easyProgress = (!isHorizontal && dy < 0 ? (-dy / 70.0) : 0.0).clamp(0.0, 1.0);

        final t = _flipAnimation.value;
        final isShowingBack = t >= 0.5;
        final flipAngle = isShowingBack ? (t - 1.0) * math.pi : t * math.pi;
        final flipShade = (math.sin(t * math.pi) * 0.14).clamp(0.0, 1.0);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Background Card 2 (Bottom layer in stack - fixed constraints via Positioned.fill + Transform)
            if (thirdCardShell != null)
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0.0, -14.0 * (1.0 - (progress * 0.5))),
                  child: Transform.scale(
                    scale: 0.92 + (0.04 * progress),
                    alignment: Alignment.topCenter,
                    child: Opacity(
                      opacity: (0.50 + (0.35 * progress)).clamp(0.0, 1.0),
                      child: thirdCardShell,
                    ),
                  ),
                ),
              ),

            // 2. Background Card 1 (Actual Next Card promoted smoothly via GPU Transform with zero relayout)
            if (nextCardLayer != null)
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0.0, -7.0 * (1.0 - progress)),
                  child: Transform.scale(
                    scale: 0.96 + (0.04 * progress),
                    alignment: Alignment.topCenter,
                    child: Opacity(
                      opacity: (0.88 + (0.12 * progress)).clamp(0.0, 1.0),
                      child: nextCardLayer,
                    ),
                  ),
                ),
              ),

            // 3. Foreground Top Card (Active interactive swipeable card)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: toggleFlip,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Transform.translate(
                  offset: currentOffset,
                  child: Transform.rotate(
                    alignment: const Alignment(0.0, 1.15),
                    angle: currentRotation,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // The 3D Flipped Card Content (cached GPU layer)
                        Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(flipAngle),
                          alignment: Alignment.center,
                          child: isShowingBack ? backFace : frontFace,
                        ),

                        // Dynamic On-Card Stamp Overlay during drag or button flight
                        if (goodProgress > 0.05 ||
                            againProgress > 0.05 ||
                            hardProgress > 0.05 ||
                            easyProgress > 0.05)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: _buildOnCardStamp(
                                goodProgress: goodProgress,
                                againProgress: againProgress,
                                hardProgress: hardProgress,
                                easyProgress: easyProgress,
                                colors: colors,
                              ),
                            ),
                          ),

                        // Subtle 3D dynamic specular shading during flip turn
                        if (flipShade > 0.01)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: Colors.black.withValues(alpha: flipShade),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOnCardStamp({
    required double goodProgress,
    required double againProgress,
    required double hardProgress,
    required double easyProgress,
    required VocaColorPalette colors,
  }) {
    // Strictly select only the single dominant direction and place at
    // center-left, center-right, center-top (below top header), or center-bottom.
    final (progress, label, icon, color, alignment) = goodProgress >= againProgress &&
            goodProgress >= hardProgress &&
            goodProgress >= easyProgress
        ? (goodProgress, 'GOOD', Icons.check_rounded, colors.success, Alignment.centerLeft)
        : againProgress >= hardProgress && againProgress >= easyProgress
            ? (againProgress, 'AGAIN', Icons.replay_rounded, colors.accentPrimary, Alignment.centerRight)
            : hardProgress >= easyProgress
                ? (hardProgress, 'HARD', Icons.timelapse_rounded, colors.colorFire, const Alignment(0.0, -0.72))
                : (easyProgress, 'EASY', Icons.bolt_rounded, colors.accentSecondary, const Alignment(0.0, 0.72));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: (progress * 0.75).clamp(0.0, 0.9)),
          width: 2.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Align(
          alignment: alignment,
          child: Opacity(
            opacity: progress.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.85 + (0.15 * progress),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: colors.bgCard.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color, width: 1.6),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeckCardShell({
    required VocaColorPalette colors,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
    );
  }
}

