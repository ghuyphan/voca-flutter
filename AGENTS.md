# Voca Flutter — AI Agent Instructions & Architectural Guide (AGENTS.md)

Critical invariants, architectural rules, and development workflows for AI coding assistants working in **Voca Flutter** (`voca_flutter`).

---

## 1. Executive Summary & Design Reference

**Voca Flutter** is the cross-platform mobile immersion application (Android, iOS, macOS) for Japanese, Chinese, Korean, and English learners using authentic YouTube videos.

- **Design Reference (`../lingua-tube`)**: The original web application (`../lingua-tube`) serves as the visual identity, UX flow, and feature reference. Inspect its Angular components (`.component.html`, `.component.scss`) when building or styling features.
- **Material 3 (M3) Mobile Framework**: Build with Google Material 3 (`ThemeData(useMaterial3: true)`), translating web concepts into native mobile M3 components ([Flutter Material Widgets](https://docs.flutter.dev/ui/widgets/material): `NavigationBar`, `FilledButton`, `SegmentedButton`, `FilterChip`, `Card`, `showModalBottomSheet`), styled with Voca design tokens. Do **not** create an inflexible 1:1 web DOM clone.
- **Shared Backends**: Cloudflare Edge (`https://voca.study`) for linguistics/video APIs; Supabase (`https://edbkvzviqeulwzcnrrlb.supabase.co`) for auth and cloud sync.

### Key Tech Stack
- **Framework**: Flutter 3.47.x / Dart 3.13.x | **UI**: Material 3 (`lib/config/voca_theme.dart`)
- **State**: `signals_flutter` (matching Angular 19 Signals) | **HTTP**: `dio`
- **Video**: `youtube_player_iframe: ^6.0.2` | **Storage**: `hive_ce` & Supabase

---

## 2. Critical Invariants (Non-Negotiable Rules)

### ⚠️ RULE 1: Follow Original App Design with Material 3 (M3)
- Use standard Flutter M3 widgets ([Flutter Material Widgets Catalog](https://docs.flutter.dev/ui/widgets/material): `NavigationBar`, `FilledButton`, `FilledButton.tonal`, `OutlinedButton`, `SegmentedButton`, `FilterChip`, `Card`, `showModalBottomSheet`, `SearchBar`).
- Consult the `material-design-3-ui` skill (`~/.gemini/config/skills/material-design-3-ui/`) for component selection, surface tonal hierarchy (`surfaceContainer*`), and anti-patterns.
- Style components using Voca tokens in `lib/config/voca_theme.dart` (Radiant Coral `#FF6B82`, Rich Obsidian dark / Crisp Porcelain light, Nunito font, 5-tier level badges). Avoid generic unthemed purple defaults.
- Adhere to mobile ergonomics: min 48x48dp touch targets, M3 state layers (ink ripples), and native sheets with drag handles.

### ⚠️ RULE 2: Mandatory Anti-Bot User-Agent Header
- Cloudflare Pages (`https://voca.study`) returns HTTP 403 `BOT_DETECTED` on generic/scraper headers.
- Every outgoing request in `VocaApiClient` MUST include:
  ```dart
  'User-Agent': 'VocaMobile/1.0.0 (Android; Mobile)' // or iOS equivalent
  ```

### ⚠️ RULE 3: YouTube Player Initialization & Embed Recovery
- **No hardcoded `key` in Controller**: Never pass a non-null `key` or use `YoutubePlayerController.fromVideoId()`. It activates `_PlayerLoadingOverlay`, trapping thumbnail opacity at 1.0 and blocking user touch input.
- Always use the standard controller initialization:
  ```dart
  _ytController = YoutubePlayerController(
    params: const YoutubePlayerParams(
      showControls: true, showFullscreenButton: true, mute: false,
      enableCaption: false, origin: 'https://www.youtube-nocookie.com',
      privacyEnhancedMode: true,
      userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
    ),
  );
  _ytController.loadVideoById(videoId: widget.videoId);
  ```
- **Error 150/152/101 Fallback**: For blocked music videos (syndication blocks), listen to controller events and render a fallback banner with a **"Watch on YouTube"** button (`url_launcher`).

### ⚠️ RULE 4: Flexible Dictionary Deserialization
- Upstream providers format examples differently (`Mazii` returns `List<String>`, `Jotoba` returns `List<Map>`).
- In `DictionaryEntry.fromJson`, inspect `e is Map` vs `e is String`. Never cast `e as Map<String, dynamic>` unconditionally.

### ⚠️ RULE 5: Signal-First Reactivity (`signals_flutter`)
- Match Angular Signals using `signal()`, `computed()`, `effect()`, and `Watch((context) => ...)`.
- Keep widgets granular and reactive; avoid sweeping global `setState()` cascades.

### ⚠️ RULE 6: Deterministic Offline IDs (Cyrb53 Base36)
- Client-side offline records MUST generate deterministic remote IDs to prevent duplicate inserts:
  ```dart
  generateDeterministicRecordId([userId, word.toLowerCase(), language]);
  ```

### ⚠️ RULE 7: Sticky Subtitle Display Rule
- Maintain subtitle display across short gaps (< 3.0s). Do not blank the screen between rapid subtitle cues.

### ⚠️ RULE 8: Two-Tier Dual Subtitle Streaming (< 200ms Seek)
- On seek/start: immediately dispatch active cue + 2 lookahead cues to `POST /api/translate/batch` (< 200ms display).
- Progressively stream remaining cues in 40–60 item background batches with exponential backoff on HTTP 429.

### ⚠️ RULE 9: Subtitle Track Selection & Mismatch
- If `languageMismatch == true`, present the Subtitle Track Picker: switch target language or generate with Gladia AI ASR (`preferAI: true` + Turnstile CAPTCHA).

### ⚠️ RULE 10: Atomic Gamification & Streaks via Supabase RPC
- Never read-modify-write streaks client-side. Always call the atomic Postgres RPC:
  ```dart
  await supabase.rpc('record_streak_activity', params: {
    'p_user_id': userId,
    'p_activity_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
  });
  ```

### ⚠️ RULE 11: NO Autonomous Git Commits
- AI agents **MUST NOT** run `git commit` autonomously unless the user explicitly directs it. Keep all changes in the working tree.

### ⚠️ RULE 12: Modern Material 3 Packages & Dependency Compatibility
- Use modern Material 3 APIs (`WidgetStateProperty` not deprecated `MaterialStateProperty`, `Color.withValues(alpha: ...)` not `withOpacity()`).
- Keep `pubspec.yaml` dependencies updated and mutually compatible with Flutter 3.24+ / 3.47+ and Dart 3.x.
- Verify with `flutter pub get` and `flutter analyze` (0 errors, 0 deprecations).

---

## 3. Design System & Component Guidelines

All design tokens are centralized in `lib/config/voca_theme.dart`:
- **Color Palette**: Obsidian Dark (`#0D0F14`) & Crisp Porcelain Light (`#F3F4F7`), Radiant Coral accent (`#FF6B82`), Mint grammar (`#10B981`), Flame streak (`#EA580C`), Sky AI diamond (`#38BDF8`).
- **Typography Scale**: `Nunito` for UI text; `Kosugi Maru` / `Noto Sans JP` (JA), `Noto Sans SC` (ZH), `Noto Sans KR` (KO) for CJK.
- **Educational Badges**: 5-tier level badges (Beginner, Elementary, Intermediate, Upper, Advanced) via `LevelColorInfo.forLevel(level, isDark: ...)`.
- **Key M3 Component Patterns**:
  - **Search**: `SearchBar` or pill container (`StadiumBorder`, `44px` height).
  - **Player & Controls**: `AspectRatio(16/9)`, overlay gestures (double-tap `±5s/10s` seek), M3 `IconButton`.
  - **Interactive Subtitles**: Ruby furigana/pinyin above tokens, tappable words with M3 touch ripples, grammar highlights.
  - **Sheets (Dict/Grammar)**: `showModalBottomSheet` (`showDragHandle: true`, `20dp` top radius, `bgCard` surface).
  - **Study Deck**: Perspective 3D flip card (`Transform` with `Matrix4`), SM-2 4-button grading dock (`Again`, `Hard`, `Good`, `Easy`).
  - **Bottom Navigation**: M3 `NavigationBar` (`80dp` height, stadium pill active indicator).

---

## 4. Key References & Documentation Map

- **Flutter Material 3 Catalog**: [docs.flutter.dev/ui/widgets/material](https://docs.flutter.dev/ui/widgets/material) (Official M3 component implementation reference)
- **Material Design 3 UI Skill**: `~/.gemini/config/skills/material-design-3-ui/` (Decision engine covering semantic tokens, component selection, accessibility, and Flutter widget mapping in `references/flutter-material-widgets.md`)
- **Detailed Architecture & Signals**: [doc/architecture.md](./doc/architecture.md)
- **Edge API & Supabase Specs**: [doc/api-integration.md](./doc/api-integration.md) & [lib/services/voca_api_client.dart](./lib/services/voca_api_client.dart)
- **Features (Subtitles, Grammar, SRS)**: [doc/features.md](./doc/features.md)
- **Design Tokens & Theme Source**: [lib/config/voca_theme.dart](./lib/config/voca_theme.dart)
- **Development & Emulator Setup**: [doc/development-guide.md](./doc/development-guide.md)

---

## 5. Development & Verification Workflow

1. **Review**: Inspect matching Angular component in `../lingua-tube` for layout and UX intent.
2. **Implement**: Build idiomatic Material 3 Flutter widgets using `package:flutter/material.dart` styled with `voca_theme.dart`.
3. **Reactivity**: Bind state using `signals_flutter` (`signal()`, `computed()`, `Watch`).
4. **Verify**:
   ```bash
   flutter pub get
   flutter analyze   # Must report 0 issues
   flutter test      # All tests must pass
   ```
