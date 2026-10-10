// lib/ui/onboarding/onboarding_controller.dart

import 'dart:ui' show PlatformDispatcher;
import 'package:signals_flutter/signals_flutter.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import 'models/onboarding_models.dart';

/// Signal-backed state for the onboarding flow.
///
/// Steps:
/// 0 Welcome · 1 Learning language · 2 Level & Daily goal ·
/// 3 Companion · 4 Ready & Starter Loot.
class OnboardingController {
  static const int welcomeStep = 0;
  static const int lastStep = 4;

  /// Number of steps shown in the progress bar (Welcome is excluded).
  static const int progressSteps = 4;

  final bool isReplay;

  final Signal<int> step;
  final Signal<bool> isForward = signal(true);
  final Signal<bool> isCompleting = signal(false);

  final Signal<String> learningLang;
  final Signal<String> nativeLang;
  final Signal<bool> showDualSubtitles;
  final Signal<String> readingDisplayMode;
  final Signal<String> level;
  final Signal<int> dailyGoal;
  final Signal<String> companion;
  final Signal<String> themeMode;

  late final Computed<bool> isFirst = computed(() => step.value == welcomeStep);
  late final Computed<bool> isLast = computed(() => step.value == lastStep);

  OnboardingController._({
    required this.isReplay,
    required int initialStep,
    required String learning,
    required String native,
    required bool dual,
    required String readingMode,
    required String lvl,
    required int goal,
    required String comp,
    required String theme,
  })  : step = signal(initialStep),
        learningLang = signal(learning),
        nativeLang = signal(native),
        showDualSubtitles = signal(dual),
        readingDisplayMode = signal(readingMode),
        level = signal(lvl),
        dailyGoal = signal(goal),
        companion = signal(comp),
        themeMode = signal(theme);

  factory OnboardingController({required bool isReplay}) {
    final app = AppState.instance;
    final s = app.userSettings.value;

    final deviceCode = PlatformDispatcher.instance.locale.languageCode;
    final detected =
        NativeLanguageOption.supportedCodes.contains(deviceCode) ? deviceCode : null;

    final learning = app.activeLanguage.value;
    String native = isReplay && s.nativeLanguage.isNotEmpty
        ? s.nativeLanguage
        : (detected ?? I18nService.instance.currentLanguage.value);
    if (native == learning) native = learning == 'en' ? 'vi' : 'en';

    final lvl = LevelOption.all.any((l) => l.id == s.preferredLevel)
        ? s.preferredLevel
        : 'beginner';

    final theme = s.themeMode.isNotEmpty ? s.themeMode : 'system';

    final readingMode = app.getReadingDisplayModeFor(learning);

    return OnboardingController._(
      isReplay: isReplay,
      initialStep: isReplay ? 1 : welcomeStep,
      learning: learning,
      native: native,
      dual: s.showDualSubtitles,
      readingMode: readingMode,
      lvl: lvl,
      goal: DailyGoalOption.byMinutes(s.dailyGoalMinutes).minutes,
      comp: isReplay
          ? CompanionOption.byId(s.companionClass).id
          : LearningLanguageOption.byCode(learning).defaultCompanion,
      theme: theme,
    );
  }

  void setThemeMode(String mode) {
    if (themeMode.value == mode) return;
    themeMode.value = mode;
    AppState.instance.setThemeMode(mode);
  }

  void setReadingDisplayMode(String mode) {
    if (readingDisplayMode.value == mode) return;
    readingDisplayMode.value = mode;
  }

  /// First step reachable via Back (Welcome is skipped on replay).
  int get firstStep => isReplay ? 1 : welcomeStep;

  bool get canGoBack => step.value > firstStep;

  void next() {
    if (step.value >= lastStep) return;
    isForward.value = true;
    step.value++;
  }

  void back() {
    if (!canGoBack) return;
    isForward.value = false;
    step.value--;
  }

  void selectLearningLanguage(String code) {
    if (learningLang.value == code) return;
    learningLang.value = code;
    readingDisplayMode.value = AppState.instance.getReadingDisplayModeFor(code);
    companion.value = LearningLanguageOption.byCode(code).defaultCompanion;
    if (nativeLang.value == code) {
      selectNativeLanguage(code == 'en' ? 'vi' : 'en');
    }
  }

  /// Also switches the app UI language live.
  void selectNativeLanguage(String code) {
    nativeLang.value = code;
    if (I18nService.instance.currentLanguage.value != code) {
      AppState.instance.setUiLanguage(code);
    }
  }

  /// Applies the detected device locale to the UI on first launch.
  void applyDetectedLocaleIfNeeded() {
    if (isReplay) return;
    if (I18nService.instance.currentLanguage.value != nativeLang.value) {
      AppState.instance.setUiLanguage(nativeLang.value);
    }
  }
}
