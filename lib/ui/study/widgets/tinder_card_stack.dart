// lib/ui/study/widgets/tinder_card_stack.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/voca_models.dart';
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
/// dynamic scaling background layers, and bouncy spring snap-back.
class TinderCardStack extends StatefulWidget {
  final Flashcard currentCard;
  final Flashcard? nextCard;
  final Flashcard? cardAfterNext;
  final bool isRevealed;
  final bool isReadingPeeked;
  final ValueChanged<SRSReviewRating> onSwipe;
  final VoidCallback onToggleFlip;
  final VoidCallback onTogglePeekReading;
  final String againInterval;
  final String goodInterval;
  final TinderStackController? controller;

  const TinderCardStack({
    super.key,
    required this.currentCard,
    this.nextCard,
    this.cardAfterNext,
    required this.isRevealed,
    required this.isReadingPeeked,
    required this.onSwipe,
    required this.onToggleFlip,
    required this.onTogglePeekReading,
    this.againInterval = '<1 min',
    this.goodInterval = '1 d',
    this.controller,
  });

  @override
  State<TinderCardStack> createState() => _TinderCardStackState();
}

class _TinderCardStackState extends State<TinderCardStack>
    with TickerProviderStateMixin {
  // Drag physics & position
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _hasHapticTriggered = false;

  // Animation controller for drag release snap-back & programmatic swipe
  late final AnimationController _flightController;
  late Animation<Offset> _flightOffsetAnimation;
  late Animation<double> _flightRotationAnimation;

  // 3D perspective flip controller
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);

    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );

    if (widget.isRevealed) {
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant TinderCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }

    if (widget.currentCard.id != oldWidget.currentCard.id) {
      _dragOffset = Offset.zero;
      _isDragging = false;
      _hasHapticTriggered = false;
      _flightController.reset();
      _flipController.reset();
      if (widget.isRevealed) {
        _flipController.value = 1.0;
      }
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
    _flightController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void toggleFlip() {
    HapticFeedback.selectionClick();
    widget.onToggleFlip();
  }

  void programmaticSwipe(SRSReviewRating rating) {
    if (_flightController.isAnimating) return;
    HapticFeedback.mediumImpact();

    final size = MediaQuery.of(context).size;
    final endOffset = switch (rating) {
      SRSReviewRating.again => Offset(-size.width * 1.5, 20),
      SRSReviewRating.good => Offset(size.width * 1.5, 20),
      SRSReviewRating.easy => Offset(0, -size.height * 1.2),
      SRSReviewRating.hard => Offset(0, size.height * 1.2),
    };

    final endRotation = switch (rating) {
      SRSReviewRating.again => -0.42,
      SRSReviewRating.good => 0.42,
      SRSReviewRating.easy => 0.0,
      SRSReviewRating.hard => 0.0,
    };

    _flightOffsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: endOffset,
    ).animate(CurvedAnimation(parent: _flightController, curve: Curves.easeOutCubic));

    _flightRotationAnimation = Tween<double>(
      begin: _calculateRotation(_dragOffset.dx, size.width),
      end: endRotation,
    ).animate(CurvedAnimation(parent: _flightController, curve: Curves.easeOutCubic));

    _flightController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      _dragOffset = Offset.zero;
      _flightController.reset();
      widget.onSwipe(rating);
    });
  }

  double _calculateRotation(double dx, double screenWidth) {
    // Natural thumb pivot rotation (approx. 18-20 degrees tilt on full drag)
    return (dx / screenWidth) * 0.60;
  }

  double _calculateProgress(Size size) {
    final horizontalRatio = (_dragOffset.dx.abs() / 110.0).clamp(0.0, 1.0);
    final verticalRatio = (_dragOffset.dy.abs() / 110.0).clamp(0.0, 1.0);
    return math.max(horizontalRatio, verticalRatio);
  }

  void _onPanStart(DragStartDetails details) {
    if (_flightController.isAnimating) return;
    setState(() {
      _isDragging = true;
      _hasHapticTriggered = false;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_flightController.isAnimating) return;
    setState(() {
      _dragOffset += details.delta;
    });

    final dist = math.max(_dragOffset.dx.abs(), _dragOffset.dy.abs());
    if (dist > 80 && !_hasHapticTriggered) {
      _hasHapticTriggered = true;
      HapticFeedback.lightImpact();
    } else if (dist <= 80 && _hasHapticTriggered) {
      _hasHapticTriggered = false;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_flightController.isAnimating) return;
    final size = MediaQuery.of(context).size;
    final velocity = details.velocity.pixelsPerSecond;

    // Reset if drag was negligible (taps are handled natively by onTap)
    if (_dragOffset.distance < 10.0) {
      setState(() {
        _isDragging = false;
        _dragOffset = Offset.zero;
      });
      return;
    }

    SRSReviewRating? rating;
    Offset targetOffset = Offset.zero;
    double targetRotation = 0.0;

    // Check dominant axis for precise multi-directional Tinder gesture recognition
    final isHorizontalDominant = _dragOffset.dx.abs() >= _dragOffset.dy.abs();
    if (isHorizontalDominant) {
      if (_dragOffset.dx > 80 || velocity.dx > 450) {
        rating = SRSReviewRating.good;
        targetOffset = Offset(size.width * 1.5, _dragOffset.dy + velocity.dy * 0.1);
        targetRotation = 0.38;
      } else if (_dragOffset.dx < -80 || velocity.dx < -450) {
        rating = SRSReviewRating.again;
        targetOffset = Offset(-size.width * 1.5, _dragOffset.dy + velocity.dy * 0.1);
        targetRotation = -0.38;
      }
    } else {
      if (_dragOffset.dy < -80 || velocity.dy < -450) {
        rating = SRSReviewRating.easy;
        targetOffset = Offset(_dragOffset.dx, -size.height * 1.2);
        targetRotation = 0.0;
      } else if (_dragOffset.dy > 80 || velocity.dy > 450) {
        rating = SRSReviewRating.hard;
        targetOffset = Offset(_dragOffset.dx, size.height * 1.2);
        targetRotation = 0.0;
      }
    }

    if (rating != null) {
      HapticFeedback.mediumImpact();
      _flightController.duration = const Duration(milliseconds: 200);
      _flightOffsetAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: targetOffset,
      ).animate(CurvedAnimation(parent: _flightController, curve: Curves.easeOutCubic));

      _flightRotationAnimation = Tween<double>(
        begin: _calculateRotation(_dragOffset.dx, size.width),
        end: targetRotation,
      ).animate(CurvedAnimation(parent: _flightController, curve: Curves.easeOutCubic));

      _flightController.forward(from: 0.0).then((_) {
        if (!mounted) return;
        setState(() {
          _isDragging = false;
          _dragOffset = Offset.zero;
        });
        _flightController.reset();
        widget.onSwipe(rating!);
      });
    } else {
      // Natural spring bounce snap-back with elastic overshoot curve
      _flightController.duration = const Duration(milliseconds: 320);
      _flightOffsetAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _flightController, curve: Curves.easeOutBack));

      _flightRotationAnimation = Tween<double>(
        begin: _calculateRotation(_dragOffset.dx, size.width),
        end: 0.0,
      ).animate(CurvedAnimation(parent: _flightController, curve: Curves.easeOutBack));

      _flightController.forward(from: 0.0).then((_) {
        if (!mounted) return;
        setState(() {
          _isDragging = false;
          _dragOffset = Offset.zero;
        });
        _flightController.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final progress = _isDragging || _flightController.isAnimating
        ? _calculateProgress(size)
        : 0.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Background Card 2 (Bottom layer in stack)
        if (widget.cardAfterNext != null)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Transform.translate(
                offset: Offset(0, 24.0 * (1.0 - progress)),
                child: Transform.scale(
                  scale: 0.88 + (0.06 * progress),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: (0.45 + (0.25 * progress)).clamp(0.0, 1.0),
                    child: RepaintBoundary(
                      child: FlashcardFace(
                        card: widget.cardAfterNext!,
                        isBack: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // 2. Background Card 1 (Middle layer in stack)
        if (widget.nextCard != null)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Transform.translate(
                offset: Offset(0, 12.0 * (1.0 - progress)),
                child: Transform.scale(
                  scale: 0.94 + (0.06 * progress),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: (0.80 + (0.20 * progress)).clamp(0.0, 1.0),
                    child: RepaintBoundary(
                      child: FlashcardFace(
                        card: widget.nextCard!,
                        isBack: false,
                      ),
                    ),
                  ),
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
            child: AnimatedBuilder(
              animation: Listenable.merge([_flightController, _flipController]),
              builder: (context, child) {
                final currentOffset = _flightController.isAnimating
                    ? _flightOffsetAnimation.value
                    : _dragOffset;

                final currentRotation = _flightController.isAnimating
                    ? _flightRotationAnimation.value
                    : _calculateRotation(_dragOffset.dx, size.width);

                final t = _flipAnimation.value;
                final isShowingBack = t >= 0.5;
                // Seamless clockwise 3D turn: front rotates 0 -> +pi/2, back rotates -pi/2 -> 0.
                // At t = 1.0, angle = 0 so local coordinates are completely identity with 0 inversion.
                final flipAngle = isShowingBack ? (t - 1.0) * math.pi : t * math.pi;
                final flipShade = (math.sin(t * math.pi) * 0.18).clamp(0.0, 1.0);

                return Transform.translate(
                  offset: currentOffset,
                  child: Transform.rotate(
                    // Anchored naturally near the bottom for realistic card swing
                    alignment: const Alignment(0.0, 1.25),
                    angle: currentRotation,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // The 3D Flipped Card Content
                        Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0012)
                            ..rotateY(flipAngle),
                          alignment: Alignment.center,
                          child: isShowingBack
                              ? FlashcardFace(
                                  card: widget.currentCard,
                                  isBack: true,
                                  againInterval: widget.againInterval,
                                  goodInterval: widget.goodInterval,
                                )
                              : FlashcardFace(
                                  card: widget.currentCard,
                                  isBack: false,
                                  isReadingPeeked: widget.isReadingPeeked,
                                  onTogglePeekReading: widget.onTogglePeekReading,
                                  againInterval: widget.againInterval,
                                  goodInterval: widget.goodInterval,
                                ),
                        ),

                        // Subtle 3D dynamic specular shading during flip turn
                        if (flipShade > 0.01)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.black.withValues(alpha: flipShade),
                                ),
                              ),
                            ),
                          ),

                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
