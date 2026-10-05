// lib/ui/splash/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../shell/main_shell.dart';
import '../onboarding/onboarding_screen.dart';

/// Authentic VOCA Splash Screen featuring the official Kikyou logo,
/// signature Obsidian background, and radiant coral accent glow.
class SplashScreen extends StatefulWidget {
  final Duration duration;
  final bool autoNavigate;
  final VoidCallback? onFinish;

  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 1400),
    this.autoNavigate = true,
    this.onFinish,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _navTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();

    if (widget.autoNavigate) {
      _navTimer = Timer(widget.duration, () {
        if (mounted && !_hasNavigated) {
          _navigateToHome();
        }
      });
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _navTimer?.cancel();

    if (widget.onFinish != null) {
      widget.onFinish!();
      return;
    }

    final hasCompleted = AppState.instance.userSettings.value.hasCompletedOnboarding;
    final Widget nextScreen = hasCompleted ? const MainShell() : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VocaTokens.bgPrimary,
      body: GestureDetector(
        onTap: widget.autoNavigate ? _navigateToHome : null,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Ambient subtle radial accent glow
            Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      VocaTokens.accentPrimary.withOpacity(0.18),
                      VocaTokens.accentPrimary.withOpacity(0.04),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Main Logo, Brand & Tagline presentation
            Center(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Master App Logo badge with squircle shadow
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: VocaTokens.accentPrimary.withOpacity(0.35),
                            blurRadius: 28,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 104,
                          height: 104,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback gradient container if image loading fails
                            return Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF7E93),
                                    Color(0xFFF45B74),
                                    Color(0xFFDF4360),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                size: 56,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // "Voca" Brand typography
                    const Text(
                      'Voca',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF8FAFC),
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle / Tagline
                    Text(
                      context.t('app.tagline', null, 'Learn Languages with YouTube'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: VocaTokens.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom loading progress accent
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 72,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.5),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF7E93),
                          Color(0xFFF45B74),
                          Color(0xFFDF4360),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
