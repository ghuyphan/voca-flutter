// lib/ui/onboarding/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../shell/main_shell.dart';
import 'steps/welcome_step.dart';
import 'steps/language_step.dart';
import 'steps/pace_level_step.dart';
import 'steps/companion_step.dart';
import 'steps/license_step.dart';
import 'widgets/onboarding_header.dart';
import 'widgets/onboarding_bottom_bar.dart';

/// Complete, high-performance, native Onboarding Screen for VOCA.
/// Features 5 guided interactive steps with tactile micro-interactions,
/// live companion speech bubble, holographic guild pass, and starter loot rewards.
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
  late final PageController _pageController;
  int _currentStep = 0;
  static const int _totalSteps = 5;
  bool _isCompleting = false;

  // Selected State Defaults
  String _selectedLearningLang = 'ja';
  String _selectedNativeLang = 'en';
  bool _showDualSubtitles = true;
  String _selectedLevel = 'beginner';
  int _selectedDailyGoal = 10;
  String _selectedCompanion = 'wizard';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize with current user settings if available
    final currentSettings = AppState.instance.userSettings.value;
    _selectedLearningLang = AppState.instance.activeLanguage.value;
    _selectedNativeLang = currentSettings.nativeLanguage.isNotEmpty
        ? currentSettings.nativeLanguage
        : I18nService.instance.currentLanguage.value;
    _showDualSubtitles = currentSettings.showDualSubtitles;
    _selectedLevel = currentSettings.preferredLevel;
    _selectedCompanion = currentSettings.companionClass;
    _selectedDailyGoal = currentSettings.dailyGoalMinutes;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _skipOnboarding() {
    _finishOnboarding(isSkipped: true);
  }

  Future<void> _finishOnboarding({bool isSkipped = false}) async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    HapticFeedback.mediumImpact();

    await AppState.instance.completeOnboarding(
      learningLanguage: _selectedLearningLang,
      companionClass: _selectedCompanion,
      preferredLevel: _selectedLevel,
      nativeLanguage: _selectedNativeLang,
      showDualSubtitles: _showDualSubtitles,
      dailyGoalMinutes: _selectedDailyGoal,
      isReplay: widget.isReplay,
    );

    if (!mounted) return;

    if (!widget.isReplay) {
      final msg = context.t(
        'onboarding.starterPackClaimed',
        null,
        'Starter Pack Activated! +50 XP & Day 1 Streak ignited.',
      );
      ToastService.show(
        context,
        msg,
        type: ToastType.success,
        duration: const Duration(milliseconds: 4000),
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

  String _getBottomBarLabel() {
    if (_currentStep == 0) {
      return context.t('onboarding.getStarted', null, 'Get Started');
    } else if (_currentStep == _totalSteps - 1) {
      return context.t('onboarding.startLearning', null, 'Start Learning');
    } else {
      return context.t('common.continue', null, 'Continue');
    }
  }

  IconData _getBottomBarIcon() {
    if (_currentStep == _totalSteps - 1) {
      return Icons.auto_awesome_rounded;
    }
    return Icons.arrow_forward_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentStep > 0) {
          _prevStep();
        }
      },
      child: Scaffold(
        backgroundColor: colors.bgPrimary,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top Header with Back, Segmented Bar & Skip
              OnboardingHeader(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
                showBack: _currentStep > 0,
                onBack: _prevStep,
                onSkip: _skipOnboarding,
              ),

              // Page Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() => _currentStep = page);
                  },
                  children: [
                    // Step 0: Welcome & Core Values
                    const WelcomeStep(),

                    // Step 1: Learning Realm & Subtitle Translation Settings
                    LanguageStep(
                      selectedLearningLanguage: _selectedLearningLang,
                      onLearningLanguageChanged: (lang) {
                        setState(() => _selectedLearningLang = lang);
                      },
                      selectedNativeLanguage: _selectedNativeLang,
                      onNativeLanguageChanged: (lang) {
                        setState(() => _selectedNativeLang = lang);
                      },
                      showDualSubtitles: _showDualSubtitles,
                      onDualSubtitlesChanged: (val) {
                        setState(() => _showDualSubtitles = val);
                      },
                    ),

                    // Step 2: Difficulty Ladder & Habit Pact
                    PaceLevelStep(
                      selectedLevel: _selectedLevel,
                      onLevelChanged: (lvl) {
                        setState(() => _selectedLevel = lvl);
                      },
                      selectedDailyGoal: _selectedDailyGoal,
                      onDailyGoalChanged: (goal) {
                        setState(() => _selectedDailyGoal = goal);
                      },
                    ),

                    // Step 3: Companion Spirit Guide Selection
                    CompanionStep(
                      selectedCompanion: _selectedCompanion,
                      onCompanionChanged: (comp) {
                        setState(() => _selectedCompanion = comp);
                      },
                    ),

                    // Step 4: Adventurer License Activated & Starter Loot Cache
                    LicenseStep(
                      learningLanguage: _selectedLearningLang,
                      rankId: _selectedLevel,
                      companionId: _selectedCompanion,
                      dailyGoalMinutes: _selectedDailyGoal,
                    ),
                  ],
                ),
              ),

              // Sticky Bottom Action Bar
              OnboardingBottomBar(
                label: _getBottomBarLabel(),
                icon: _getBottomBarIcon(),
                onPressed: _nextStep,
                isLoading: _isCompleting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
