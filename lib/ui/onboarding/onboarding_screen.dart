// lib/ui/onboarding/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/voca_theme.dart';
import '../../services/haptic_service.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../auth/auth_screen.dart';
import '../shell/main_shell.dart';
import 'onboarding_controller.dart';
import 'steps/welcome_step.dart';
import 'steps/learning_language_step.dart';
import 'steps/level_goal_step.dart';
import 'steps/companion_step.dart';
import 'steps/ready_step.dart';
import 'widgets/onboarding_header.dart';
import 'widgets/onboarding_bottom_bar.dart';

/// Complete, modern native Onboarding Screen for VOCA.
/// 5-step intuitive flow with zero image dependencies, signal reactivity,
/// live companion preview, and smooth page navigation with smart device-locale detection.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onFinish;
  final bool isReplay;

  const OnboardingScreen({
    super.key,
    this.onFinish,
    this.isReplay = false,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final OnboardingController _controller;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _controller = OnboardingController(isReplay: widget.isReplay);
    _pageController = PageController(initialPage: _controller.step.value);

    // Auto-apply detected device locale if first time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.applyDetectedLocaleIfNeeded();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_controller.step.value < OnboardingController.lastStep) {
      _controller.next();
      _pageController.animateToPage(
        _controller.step.value,
        duration: const Duration(milliseconds: 360),
        curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      );
    } else {
      _finishOnboarding();
    }
  }

  void _prevStep() {
    if (_controller.canGoBack) {
      _controller.back();
      _pageController.animateToPage(
        _controller.step.value,
        duration: const Duration(milliseconds: 360),
        curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      );
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _skipOnboarding() {
    _finishOnboarding(isSkipped: true);
  }

  Future<void> _openAuth() async {
    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    if (loggedIn == true && mounted) {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding({bool isSkipped = false}) async {
    if (_controller.isCompleting.value) return;
    _controller.isCompleting.value = true;

    HapticService.medium();

    final perkMsg = await AppState.instance.completeOnboarding(
      learningLanguage: _controller.learningLang.value,
      companionClass: _controller.companion.value,
      preferredLevel: _controller.level.value,
      nativeLanguage: _controller.nativeLang.value,
      showDualSubtitles: _controller.showDualSubtitles.value,
      dailyGoalMinutes: _controller.dailyGoal.value,
      isReplay: widget.isReplay,
    );

    if (!mounted) return;

    if (!widget.isReplay) {
      final baseMsg = context.t(
        'onboarding.starterPackClaimed',
        null,
        'Starter Pack Activated! +50 XP & Day 1 Streak ignited.',
      );
      final toastMessage = perkMsg.isNotEmpty ? '$baseMsg $perkMsg' : baseMsg;

      ToastService.show(
        context,
        toastMessage,
        type: ToastType.success,
        duration: const Duration(milliseconds: 4500),
      );
    } else {
      ToastService.show(
        context,
        perkMsg.isNotEmpty
            ? perkMsg
            : context.t('onboarding.saveCalibration', null, 'Preferences saved!'),
        type: ToastType.success,
        duration: const Duration(milliseconds: 3000),
      );
    }

    if (widget.onFinish != null) {
      widget.onFinish!();
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) => const MainShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _openLegalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getBottomBarLabel(int currentStep) {
    if (currentStep == OnboardingController.lastStep) {
      if (widget.isReplay) {
        return context.t('onboarding.saveCalibration', null, 'Save Changes');
      }
      return context.t('onboarding.startLearning', null, 'Start Learning');
    }
    return context.t('onboarding.continue', null, 'Continue');
  }

  IconData? _getBottomBarIcon(int currentStep) {
    if (currentStep == OnboardingController.welcomeStep) {
      return null;
    }
    if (currentStep == OnboardingController.lastStep) {
      return widget.isReplay ? Icons.check_rounded : Icons.auto_awesome_rounded;
    }
    return Icons.arrow_forward_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Watch((context) {
      final currentStep = _controller.step.value;
      final learningLang = _controller.learningLang.value;
      final nativeLang = _controller.nativeLang.value;
      final selectedLevel = _controller.level.value;
      final selectedDailyGoal = _controller.dailyGoal.value;
      final selectedCompanion = _controller.companion.value;
      final selectedThemeMode = _controller.themeMode.value;
      final isCompleting = _controller.isCompleting.value;
      final canGoBack = _controller.canGoBack;

      return PopScope(
        canPop: !canGoBack,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && canGoBack) {
            _prevStep();
          }
        },
        child: Scaffold(
          backgroundColor: colors.bgPrimary,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors.isDark
                    ? [colors.bgPrimary, colors.bgSecondary, colors.bgTertiary]
                    : [colors.bgPrimary, colors.bgSurface, colors.bgSecondary],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      // Top Header with Back, Segmented Bar, Locale Picker & Skip
                      OnboardingHeader(
                        progress: currentStep,
                        totalSegments: OnboardingController.progressSteps,
                        showBack: canGoBack || Navigator.of(context).canPop(),
                        showSkip: currentStep < OnboardingController.lastStep,
                        onBack: _prevStep,
                        onSkip: _skipOnboarding,
                        currentLanguage: nativeLang,
                        onLanguageChanged: _controller.selectNativeLanguage,
                      ),

                      // Page Content (5 Steps)
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const ClampingScrollPhysics(),
                          onPageChanged: (page) {
                            _controller.step.value = page;
                          },
                          children: [
                            // Step 0: Welcome & Core Values
                            WelcomeStep(demoLanguage: learningLang),

                            // Step 1: Target Learning Language
                            LearningLanguageStep(
                              selectedLanguage: learningLang,
                              onSelect: _controller.selectLearningLanguage,
                            ),

                            // Step 2: Difficulty Ladder & Habit Pact
                            LevelGoalStep(
                              learningLanguage: learningLang,
                              selectedLevel: selectedLevel,
                              onSelectLevel: (lvl) {
                                _controller.level.value = lvl;
                              },
                              selectedDailyGoal: selectedDailyGoal,
                              onSelectDailyGoal: (goal) {
                                _controller.dailyGoal.value = goal;
                              },
                            ),

                            // Step 3: Companion Spirit Guide
                            CompanionStep(
                              selectedCompanion: selectedCompanion,
                              onCompanionChanged: (comp) {
                                _controller.companion.value = comp;
                              },
                            ),

                            // Step 4: Plan Summary, Starter Loot & Appearance
                            ReadyStep(
                              learningLanguage: learningLang,
                              selectedLevel: selectedLevel,
                              selectedCompanion: selectedCompanion,
                              dailyGoal: selectedDailyGoal,
                              themeMode: selectedThemeMode,
                              onThemeChanged: _controller.setThemeMode,
                            ),
                          ],
                        ),
                      ),

                      // Sticky Bottom Action Bar with Optional Consent & Secondary Link on Step 0
                      OnboardingBottomBar(
                        label: _getBottomBarLabel(currentStep),
                        icon: _getBottomBarIcon(currentStep),
                        onPressed: _nextStep,
                        isLoading: isCompleting,
                        showConsent: currentStep == OnboardingController.welcomeStep,
                        onTermsTap: () => _openLegalUrl('https://voca.study/terms'),
                        onPrivacyTap: () => _openLegalUrl('https://voca.study/privacy'),
                        secondaryLabel: currentStep == OnboardingController.welcomeStep
                            ? context.t(
                                'auth.alreadyHaveAccount',
                                null,
                                'Already have an account? Sign in',
                              )
                            : null,
                        onSecondary: currentStep == OnboardingController.welcomeStep
                            ? _openAuth
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ),
      ),
    );
    });
  }
}
