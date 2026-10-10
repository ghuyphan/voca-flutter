// lib/ui/widgets/voca_audio_pulse_button.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../services/haptic_service.dart';

/// Interactive audio speaker button with radiating sound wave breathing pulse
/// when audio playback is actively playing.
class VocaAudioPulseButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  final String tooltip;
  final double size;
  final double iconSize;

  const VocaAudioPulseButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
    required this.tooltip,
    this.size = 32.0,
    this.iconSize = 15.0,
  });

  @override
  State<VocaAudioPulseButton> createState() => _VocaAudioPulseButtonState();
}

class _VocaAudioPulseButtonState extends State<VocaAudioPulseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isPlaying) {
      _checkAndStart();
    }
  }

  void _checkAndStart() {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!reduceMotion && widget.isPlaying) {
      _animController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VocaAudioPulseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _checkAndStart();
      } else {
        _animController.stop();
        _animController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: SizedBox(
          width: widget.size + 8,
          height: widget.size + 8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Radiating soundwave pulse ring
              if (widget.isPlaying && !reduceMotion)
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    final progress = _animController.value;
                    final scale = 1.0 + (0.45 * progress);
                    final alpha = 0.40 * (1.0 - progress);

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.accentPrimary.withValues(alpha: alpha),
                        ),
                      ),
                    );
                  },
                ),

              // Core button
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isPlaying ? colors.accentPrimary : colors.bgSurface,
                  border: Border.all(
                    color: widget.isPlaying ? colors.accentPrimary : colors.borderColorLight,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkResponse(
                    onTap: () {
                      HapticService.selection();
                      widget.onPressed();
                    },
                    containedInkWell: true,
                    highlightShape: BoxShape.circle,
                    radius: widget.size / 2,
                    child: Center(
                      child: Icon(
                        widget.isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                        size: widget.iconSize,
                        color: widget.isPlaying ? Colors.white : colors.textMuted,
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
  }
}
