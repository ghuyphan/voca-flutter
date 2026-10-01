# Voca Flutter — Developer Setup & Troubleshooting Guide

This guide provides setup instructions, development workflows, testing commands, and platform troubleshooting for engineers and AI agents working on **Voca Flutter**.

---

## 1. Prerequisites & Environment

- **Flutter SDK**: `>= 3.19.0` (Recommended: `3.47.x`)
- **Dart SDK**: `>= 3.3.0` (Recommended: `3.13.x`)
- **Android Development**:
  - Android SDK Platform 34 or 35 (API 34/35/36)
  - Android NDK `28.2.13676358` (Installed at `~/Library/Android/sdk/ndk/28.2.13676358`)
- **iOS & macOS Development**:
  - Xcode 15 or 16
  - CocoaPods 1.15+

---

## 2. Common Development Commands

### Install Dependencies
```bash
flutter pub get
```

### Run Static Analysis
Always run before submitting code. Aim for 0 issues:
```bash
flutter analyze
```

### Run Automated Unit Tests
Runs Cyrb53 deterministic ID tests, SM-2 Spaced Repetition engine tests, and model serialization tests:
```bash
flutter test
```

### Run on macOS Desktop (Fastest Iteration)
macOS desktop runs natively using Apple Metal GPU acceleration and does not suffer from Android emulator GPU overhead:
```bash
flutter run -d macos
```

### Run on Android Emulator
```bash
flutter run -d emulator-5554
```

---

## 3. Platform Gotchas & Troubleshooting

### A. Android Emulator Mesa Vulkan Crash (`E/MESA: Failed to open rendernode`)
- **Symptom**: The app crashes silently or loses connection (`Lost connection to device`) when loading a video in the Android Emulator.
- **Cause**: By default, standard Android emulator command-line invocations use SwiftShader/Mesa software Vulkan drivers. When the internal Chromium WebView requests hardware video decoding, Mesa fails to find the virtual GPU render node:
  ```
  E/MESA: Failed to open rendernode: No such file or directory
  E/chromium: [ERROR:aw_browser_terminator.cc(165)] Renderer process (6020) crash detected (code -1).
  ```
- **Fix**: When booting the Android emulator, always pass `-gpu host` to bridge the emulator directly to your Mac's Metal GPU:
  ```bash
  $ANDROID_HOME/emulator/emulator -avd Codex_MeoDex -gpu host
  ```

### B. YouTube Embed Error `152-4`
- **Symptom**: Player displays *"This video is unavailable. Watch on YouTube (152-4)"*.
- **Fix**: In `YoutubePlayerParams`, ensure `origin` is set to `'https://www.youtube-nocookie.com'` and `privacyEnhancedMode: true`.

### C. Persistent Thumbnail / Frozen Player
- **Symptom**: Player only displays the video's static thumbnail image, with no controls or playback response.
- **Fix**: In `YoutubePlayerController`, do not pass a `key` argument, and pass `backgroundColor: Colors.transparent` to `YoutubePlayer`.

### D. Android ProGuard & Gradle 9 Compatibility
- **Symptom**: `getDefaultProguardFile('proguard-android.txt')` build errors.
- **Fix**: Use `proguard-android-optimize.txt` in all Gradle build scripts.

---

## 4. Git & Contribution Rules for AI Agents

1. **NO Autonomous Commits**: Never run `git commit` autonomously unless the USER explicitly directs you to commit.
2. **Verification Before Concluding**: Always verify changes with `flutter analyze` and `flutter test` before reporting completion to the user.
3. **Keep Codebase Isolated**: Never write files from `voca_flutter` back into `lingua-tube` or vice versa.
