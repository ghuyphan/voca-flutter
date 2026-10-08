// lib/ui/study/widgets/tinder_action_dock.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';

/// Clean, tactile 4-button SRS Action Dock matching the canonical review UI.
/// Features centered swipe hint and 4 large rounded buttons (Again, Hard, Good, Easy)
/// with colored borders, intervals, and subtle spring press micro-interactions.
class TinderActionDock extends StatelessWidget {
  final String againInterval;
  final String hardInterval;
  final String goodInterval;
  final String easyInterval;
  final VoidCallback onAgain;
  final VoidCallback onHard;
  final VoidCallback onGood;
  final VoidCallback onEasy;

  const TinderActionDock({
    super.key,
    this.againInterval = '<1 min',
    this.hardInterval = '1 d',
    this.goodInterval = '1 d',
    this.easyInterval = '2 d',
    required this.onAgain,
    required this.onHard,
    required this.onGood,
    required this.onEasy,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Centered Gesture Hint matching reference UI
          Text(
            context.t('study.swipeHintShort', null, 'Swipe right: Good · left: Again'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // Row of 4 Tactile Action Buttons [ Again | Hard | Good | Easy ]
          Row(
            children: [
              // 1. Again
              Expanded(
                child: _SrsActionButton(
                  title: context.t('study.again', null, 'Again'),
                  interval: againInterval,
                  borderColor: const Color(0xFFE11D48),
                  bgColor: isDark
                      ? const Color(0xFFE11D48).withValues(alpha: 0.18)
                      : const Color(0xFFFDE8EC),
                  textColor: const Color(0xFFD9264E),
                  onTap: onAgain,
                ),
              ),
              const SizedBox(width: 8),

              // 2. Hard
              Expanded(
                child: _SrsActionButton(
                  title: context.t('study.hard', null, 'Hard'),
                  interval: hardInterval,
                  borderColor: const Color(0xFFF97316),
                  bgColor: isDark
                      ? const Color(0xFFF97316).withValues(alpha: 0.18)
                      : const Color(0xFFFFF3E0),
                  textColor: const Color(0xFFEA580C),
                  onTap: onHard,
                ),
              ),
              const SizedBox(width: 8),

              // 3. Good
              Expanded(
                child: _SrsActionButton(
                  title: context.t('study.good', null, 'Good'),
                  interval: goodInterval,
                  borderColor: const Color(0xFFEF4444),
                  bgColor: isDark
                      ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                      : const Color(0xFFFDE8E8),
                  textColor: const Color(0xFFDC2626),
                  onTap: onGood,
                ),
              ),
              const SizedBox(width: 8),

              // 4. Easy
              Expanded(
                child: _SrsActionButton(
                  title: context.t('study.easy', null, 'Easy'),
                  interval: easyInterval,
                  borderColor: const Color(0xFF14B8A6),
                  bgColor: isDark
                      ? const Color(0xFF14B8A6).withValues(alpha: 0.18)
                      : const Color(0xFFE0F7F6),
                  textColor: const Color(0xFF0D9488),
                  onTap: onEasy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tactile rounded push button matching the screenshot's tactile aesthetic
class _SrsActionButton extends StatefulWidget {
  final String title;
  final String interval;
  final Color borderColor;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const _SrsActionButton({
    required this.title,
    required this.interval,
    required this.borderColor,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_SrsActionButton> createState() => _SrsActionButtonState();
}

class _SrsActionButtonState extends State<_SrsActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.borderColor,
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.borderColor.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.interval,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.textColor.withValues(alpha: 0.85),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
