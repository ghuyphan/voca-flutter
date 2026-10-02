# Voca Flutter — AI Agent Instructions & Architectural Guide (AGENTS.md)

This document provides essential instructions, architectural design, codebase maps, critical invariants, and development workflows for AI coding assistants working in the **Voca Flutter** mobile repository (`voca_flutter`).

---

## 1. Executive Summary & Purpose

**Voca Flutter** is the official cross-platform mobile application (Android & iOS) for Voca (formerly LinguaTube). It provides language learners (specifically **Japanese**, **Chinese**, **Korean**, and **English**) with an interactive immersion experience using authentic YouTube videos:
- Synchronized interactive subtitles with Ruby/Furigana (Japanese), Pinyin with tone marks (Chinese), and Romaji (Japanese & Korean).
- Morphological tokenization via Edge Cloudflare Functions.
- Client-side grammar pattern detection (JLPT N5–N1, HSK 1–6, TOPIK 1–6, CEFR A1–C2).
- Multi-source dictionary lookups (Mazii, Jotoba, Naver, MDBG, FreeDict).
- SM-2 Spaced Repetition (SRS) vocabulary deck with deterministic offline-first sync.
- Dual backend architecture: Cloudflare Edge (`https://voca.study`) for public linguistics/video APIs, and Supabase for cloud user persistence.

### 📌 Canonical Source-of-Truth: The Original Web App (`../lingua-tube`)
The original web application is located at `../lingua-tube` (`/Users/huyphan/Downloads/web-app/lingua-tube`).
- **Design & UX Authority**: Whenever in doubt regarding visual design, color tokens, layout hierarchy, gestures, audio cues, bottom sheet behaviors, or edge API integrations, **always inspect and follow `../lingua-tube`**.
- **Shared Data & API Contracts**: Both apps share identical Cloudflare Edge APIs (`https://voca.study`), Supabase schemas (`https://edbkvzviqeulwzcnrrlb.supabase.co`), and grammar database structures.

### Key Technologies
- **Framework**: Flutter 3.47.x / Dart 3.13.x
- **State Management**: `signals_flutter` (directly matching the Angular 19 Signal-first reactivity model)
- **Networking**: `dio` (with mandatory anti-bot `User-Agent` and tokenization payload shaping)
- **Video Playback**: `youtube_player_flutter: ^10.0.1` (backed by `youtube_player_iframe: ^6.0.2` and `webview_flutter`)
- **Backend & Cloud Persistence**: Supabase (`https://edbkvzviqeulwzcnrrlb.supabase.co`) for Auth, Flashcards, Streaks, Playlists, and Watch History
- **Offline Storage**: `hive_ce` / `hive_ce_flutter` for local caching and deterministic ID resolution

---

## 2. Critical Invariants (Non-Negotiable Rules)

### ⚠️ RULE 1: Mandatory Anti-Bot User-Agent Header
- The Cloudflare Pages edge (`https://voca.study`) strictly enforces Cloudflare bot protection. Generic Dart/HTTP scraper headers return HTTP 403 `{"error":"Access denied: automated requests not allowed","code":"BOT_DETECTED"}`.
- Every outgoing HTTP request from `VocaApiClient` MUST include a valid mobile client User-Agent:
  ```dart
  'User-Agent': 'VocaMobile/1.0.0 (Android; Mobile)' // or iOS equivalent
  ```

### ⚠️ RULE 2: YouTube Player Initialization & Embed Recovery
- **No Hardcoded `key` in Controller**: Do NOT use `YoutubePlayerController.fromVideoId(videoId: ...)` or supply a non-null `key`. Doing so activates the internal `_PlayerLoadingOverlay` in `youtube_player_iframe`, which forces a static thumbnail image over the player at `opacity: 1.0` during `unStarted` states and blocks all user touch input.
- **Always Initialize via Standard Controller**:
  ```dart
  _ytController = YoutubePlayerController(
    params: const YoutubePlayerParams(
      showControls: true,
      showFullscreenButton: true,
      mute: false,
      enableCaption: false,
      origin: 'https://www.youtube-nocookie.com',
      privacyEnhancedMode: true,
      userAgent: 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
    ),
  );
  _ytController.loadVideoById(videoId: widget.videoId);
  ```
- **Error 150/152/101 Fallback**: Certain official music videos (e.g. Sony, Stone Music, avex) have syndication blocks that prevent third-party embedding. Always listen to `_ytController.listen((value) { ... })` and render a fallback banner with a **"Watch on YouTube"** button (`url_launcher`) so learners can study the transcript and vocabulary in Voca while watching externally.

### ⚠️ RULE 3: Flexible Dictionary Model Deserialization
- Upstream dictionary providers format example sentences differently:
  - **Mazii (JA-VI)** returns string arrays: `examples: ["例文 (Dịch nghĩa)"]`.
  - **Jotoba (JA-EN)** returns map arrays: `examples: [{"sentence": "...", "translation": "..."}]`.
- In `lib/models/voca_models.dart`, `DictionaryEntry.fromJson` MUST handle both `e is Map` and `e is String`. Never cast `e as Map<String, dynamic>` unconditionally.

### ⚠️ RULE 4: Signal-First Reactivity with `signals_flutter`
- Match the Angular 19 Signal architecture from `lingua-tube` using `signal()`, `computed()`, `effect()`, and `Watch((context) => ...)`.
- Keep widgets clean, isolated, and reactive without unnecessary `setState()` cascades across global scope.

### ⚠️ RULE 5: Deterministic Offline IDs (Cyrb53 Base36)
- Client-side offline records (vocabulary cards, study logs) MUST generate deterministic remote IDs using Cyrb53 Base36:
  ```dart
  generateDeterministicRecordId([userId, word.toLowerCase(), language]);
  // Cyrb53 Base36: base36(userId + '|' + word + '|' + lang).slice(0, 15)
  ```
- This prevents duplicate records when syncing back to Supabase upon reconnection.

### ⚠️ RULE 6: Sticky Subtitle Display Rule
- Do NOT clear active subtitles immediately on brief timestamp gaps (< 3.0 seconds).
- Subtitles must remain visible on screen until the next cue starts to ensure comfortable reading for learners.

### ⚠️ RULE 7: Two-Tier Dual Subtitle Streaming (< 200ms Seek Latency)
- When seeking or starting playback, DO NOT block the UI waiting for whole-video translations.
- **Tier 1 (Urgent seek micro-batch)**: Dispatch active cue + 2 lookahead cues (`cues[i..i+2]`) to `POST /api/translate/batch` (< 200ms display).
- **Tier 2 (Progressive background stream)**: Stream remaining cues in batches of 40–60 items with exponential backoff on HTTP 429.

### ⚠️ RULE 8: Subtitle Track Selection & Language Mismatch Handling
- When `languageMismatch === true` (video captions exist only in an alternate language), present the Subtitle Track Picker sheet offering:
  1. *Switch Target Language*: View captions in one of `availableLanguages.native`.
  2. *Generate with AI*: Trigger Gladia ASR with `preferAI: true` and Turnstile CAPTCHA to transcribe audio into target learning language.

### ⚠️ RULE 9: Atomic Gamification & Streaks via Supabase RPC
- For streak updates, NEVER do a client-side read-modify-write. Always call the atomic Postgres RPC:
  ```dart
  await supabase.rpc('record_streak_activity', params: {
    'p_user_id': userId,
    'p_activity_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
  });
  ```

### ⚠️ RULE 10: NO Autonomous Git Commits
- AI agents **MUST NOT** run `git commit` autonomously unless the USER explicitly directs you to commit.
- Keep all modifications in the working tree for review.

---

## 3. Design System & Visual Fidelity (Faithful to Original App)

All visual styling, color palettes, and component aesthetics MUST strictly align with the original design tokens defined in `../lingua-tube/src/styles/_variables.scss`:

### 3.1. Color Palette Tokens (`lib/config/voca_theme.dart`)

| Token | Dark Mode (Rich Obsidian) | Light Mode (Crisp Porcelain) | Purpose / Semantic |
| :--- | :--- | :--- | :--- |
| `bgPrimary` | `#0D0F14` | `#F3F4F7` | Scaffold & main background |
| `bgSecondary` | `#13161F` | `#E8EAF0` | Section backgrounds & navigation |
| `bgCard` | `#181B24` | `#FFFFFF` | Elevated cards, tiles, bottom sheets |
| `bgSurface` | `#1E222D` | `#F8F9FB` | Surface containers & pill chips |
| `borderColor` | `#272D3B` | `#E2E5EC` | Standard subtle borders (1px) |
| `textPrimary` | `#F1F3F7` | `#181D27` | High-contrast body text (WCAG AAA) |
| `textSecondary`| `#969EB2` | `#535862` | Secondary descriptions & subtitles |
| `textMuted` | `#7D879F` | `#717680` | Placeholders & timestamps |
| `accentPrimary`| `#FF6B82` (Coral) | `#E84562` (Strawberry) | Brand signature, active tabs, buttons |
| `accentSecondary`| `#A78BFA` (Purple) | `#7C3AED` | Secondary action highlights |
| `accentTertiary`| `#FBBF24` (Amber) | `#D97706` | Warning states & special highlights |
| `colorFire` | `#FB923C` / `#EA580C` | `#EA580C` | Daily streak flame icon & badge |
| `colorDiamond` | `#38BDF8` / `#0284C7` | `#0284C7` | AI credits & translation quota |
| `colorGrammar` | `#2DD4BF` / `#10B981` | `#10B981` | Grammar token span highlight |

### 3.2. Standard Educational Level Badges (5 Tiers)

Colors must be dynamically rendered via `LevelColorInfo.forLevel(level, isDark: ...)`:

| Tier | Levels Covered | Background (Dark / Light) | Text Color (Dark / Light) |
| :--- | :--- | :--- | :--- |
| **Beginner** | JLPT N5, HSK 1, TOPIK 1, CEFR A1 | `rgba(88, 175, 255, 0.14)` / `#E6F2FF` | `#9BCEFF` / `#0E60B8` |
| **Elementary** | JLPT N4, HSK 2, TOPIK 2, CEFR A2 | `rgba(56, 217, 238, 0.14)` / `#E2F6F9` | `#67E8F9` / `#087382` |
| **Intermediate**| JLPT N3, HSK 3-4, TOPIK 3-4, CEFR B1 | `rgba(251, 197, 61, 0.14)` / `#FEF3D6` | `#FDE068` / `#8B5700` |
| **Upper** | JLPT N2, HSK 5, TOPIK 5, CEFR B2 | `rgba(251, 146, 60, 0.14)` / `#FFF0E5` | `#FDBA74` / `#A74A00` |
| **Advanced** | JLPT N1, HSK 6, TOPIK 6, CEFR C1-C2 | `rgba(255, 120, 145, 0.14)` / `#FFEBF0` | `#FFA4B5` / `#C42B47` |

### 3.3. Reusable UI Components Matrix
Always use existing shared widgets in `lib/ui/widgets/` and `lib/ui/sheets/` rather than re-creating custom implementations:
- `VocaBottomSheet`: Base modal sheet with drag handle, backdrop blur, and safe area clamping.
- `SpotlightModal`: Centered popup for dialogs, level selection, and confirmation prompts.
- `VocaLevelBadge`: Clean rounded badge displaying standardized level colors.
- `VocaSearchInput`: Search bar with instant clear button and YouTube paste detection.
- `VocaShimmer`: Skeleton loading state matching card dimensions.
- `InteractiveSubtitleView`: Full interactive cue renderer with Ruby furigana, pinyin, and tap-to-inspect.
- `MiniplayerBar`: Docked bottom playback bar floating above navigation when minimized.

---

## 4. Original App (`lingua-tube`) $\rightarrow$ Flutter (`voca_flutter`) Porting Blueprint

This matrix maps every subsystem and component from the original Angular 19 codebase to the Flutter mobile implementation:

```
┌────────────────────────────────────────────────────────────────────────┐
│             PORTING ARCHITECTURE: ANGULAR 19 -> FLUTTER                │
└────────────────────────────────────────────────────────────────────────┘

 [ Original Web App (lingua-tube) ]           [ Mobile App (voca_flutter) ]
 ──────────────────────────────────           ─────────────────────────────
 src/styles/_variables.scss             ───>  lib/config/voca_theme.dart
 src/app/models/*.ts                    ───>  lib/models/voca_models.dart
 src/app/services/api.service.ts        ───>  lib/services/voca_api_client.dart
 src/app/services/grammar.service.ts    ───>  lib/services/grammar_engine.dart
 src/app/core/repositories/*.ts         ───>  lib/services/supabase_service.dart
 src/app/services/streak.service.ts     ───>  lib/services/gamification_service.dart

 FEATURES:
 src/app/features/video/video-player    ───>  lib/ui/video/video_player_screen.dart
 src/app/features/video/subtitle-display───>  lib/ui/widgets/interactive_subtitle_view.dart
 src/app/features/video/transcript-list ───>  lib/ui/video/transcript_view.dart
 src/app/features/video/miniplayer      ───>  lib/ui/video/miniplayer_bar.dart
 src/app/features/dictionary/dict-sheet ───>  lib/ui/sheets/dictionary_bottom_sheet.dart
 src/app/features/study/study-deck      ───>  lib/ui/study/study_deck_screen.dart
 src/app/features/vocabulary/vocab-list ───>  lib/ui/vocabulary/vocabulary_screen.dart
 src/app/features/playlist/*            ───>  lib/ui/library/library_screen.dart
 src/app/components/navigation/*        ───>  lib/ui/shell/main_shell.dart
 src/app/components/settings-sheet/*    ───>  lib/ui/settings/settings_screen.dart
```

### 4.1. Detailed Component & Service Porting Reference

| Domain | Original Angular File (`lingua-tube`) | Flutter Destination (`voca_flutter`) | Status & Key Logic |
| :--- | :--- | :--- | :--- |
| **Shell & Nav** | `src/app/components/sidebar/` | `lib/ui/shell/main_shell.dart` | Persistent Material 3 `NavigationBar` (80dp height) with 5 tabs |
| **Video Player** | `src/app/features/video/video-player.component.ts` | `lib/ui/video/video_player_screen.dart` | YouTube IFrame player, landscape rotation, error recovery |
| **Subtitles** | `src/app/features/video/subtitle-display.component.ts` | `lib/ui/widgets/interactive_subtitle_view.dart` | Ruby furigana, pinyin, romaji, token tap highlighting |
| **Transcript** | `src/app/features/video/transcript-view.component.ts` | `lib/ui/video/transcript_view.dart` | Auto-scrolling cue list, jump to time, search filtering |
| **Controls** | `src/app/features/video/player-controls/` | `lib/ui/video/video_header.dart`, `center_controls.dart`, `video_bottom_bar.dart` | Video progress scrubber, speed menu, loop, track picker |
| **Miniplayer** | `src/app/features/video/miniplayer.component.ts` | `lib/ui/video/miniplayer_bar.dart` | Docked 60dp floating bar with thumbnail, title, play/close |
| **Dictionary** | `src/app/features/dictionary/dict-modal.component.ts` | `lib/ui/sheets/dictionary_bottom_sheet.dart` | Multi-source lookups, audio speech, "Save Word" CTA |
| **Grammar** | `src/app/features/grammar/grammar-modal.component.ts` | `lib/ui/sheets/grammar_bottom_sheet.dart` | Pattern badge, formation, explanations, authentic examples |
| **Study Deck** | `src/app/features/study/study-page.component.ts` | `lib/ui/study/study_deck_screen.dart` | SM-2 SRS review deck, flip animation, Again/Hard/Good/Easy |
| **Vocabulary** | `src/app/features/vocabulary/vocabulary-list.component.ts`| `lib/ui/vocabulary/vocabulary_screen.dart` | Saved words list, level filters, search, word detail sheet |
| **Library** | `src/app/features/playlist/`, `history/` | `lib/ui/library/library_screen.dart` | Watch history cards, custom playlists, favorite videos |
| **Profile** | `src/app/components/profile-modal.component.ts` | `lib/ui/profile/profile_screen.dart` | User stats, streak flame counter, diamond balance, sign-in |
| **Settings** | `src/app/components/settings-sheet.component.ts` | `lib/ui/settings/settings_screen.dart` | Native/learning language pickers, ruby toggles, theme mode |

### 4.2. State Management Translation: Angular Signals $\rightarrow$ Flutter `signals_flutter`

The original app relies heavily on Angular 19 Signals. Flutter ports MUST use `signals_flutter` to mirror this architecture 1:1:

| Angular 19 Concept | Flutter `signals_flutter` Equivalent | Example Pattern |
| :--- | :--- | :--- |
| `signal(initialValue)` | `signal<T>(initialValue)` | `final activeCue = signal<SubtitleCue?>(null);` |
| `computed(() => ...)` | `computed<T>(() => ...)` | `final isReady = computed(() => activeCue.value != null);` |
| `effect(() => ...)` | `effect(() => ...)` | `effect(() { print(activeCue.value); });` |
| Signal read in template | `Watch((context) => ...)` | `Watch((context) => Text(activeCue.value?.text ?? ''))` |
| Signal write | `.set(value)` or `.value = ...` | `activeCue.value = nextCue;` |

---

## 5. Master Edge API Specification (`https://voca.study/api/*`)

All network requests must route through `VocaApiClient` targeting the Cloudflare Edge API:

| # | Endpoint | Method | Key Parameters | Purpose |
|:---:|:---|:---:|:---|:---|
| 1 | `/api/transcript` | `POST` | `videoId`, `lang`, `preferAI`, `jobId`, `turnstileToken` | Fetch native/cached transcript or queue Gladia ASR |
| 2 | `/api/dual-subtitles` | `POST` | `videoId`, `sourceLang`, `targetLang`, `segments` | Full video synchronized bilingual subtitle cache |
| 3 | `/api/dict` | `GET` | `?word=&from=&to=` | Multi-source dictionary lookup (Mazii, Jotoba, Naver, MDBG) |
| 4 | `/api/tokenize/:lang` | `POST` | `{ "text": "..." }` | Single-text morphological tokenization |
| 5 | `/api/tokenize-batch/:lang` | `POST` | `{ "videoId": "...", "texts": [...] }` | Batch tokenization for subtitles (up to 800 cues) |
| 6 | `/api/translate/:src/:tgt/:txt` | `GET` | URL encoded path | Single phrase translation proxy |
| 7 | `/api/translate/batch` | `POST` | `{ "texts": [...], "source": "...", "target": "..." }` | Urgent seek micro-batch (<200ms) & streaming |
| 8 | `/api/video-info` | `GET` | `?videoId=...` | YouTube metadata, duration, native caption languages |
| 9 | `/api/recommended-videos`| `GET` | `?lang=&tier=&limit=&offset=` | Verified videos with pre-cached transcripts |
| 10| `/api/video-level` | `POST` | `{ "videoId": "...", "language": "...", "level": "..." }` | Submit video difficulty rating |
| 11| `/api/diamonds` | `GET` | `Authorization: Bearer <JWT>` (opt) | AI Diamond credits, capacity, regen timer |
| 12| `/api/leaderboard` | `GET` | None | XP leaderboard rankings |
| 13| `/api/leaderboard` | `POST` | `{ "xp": ..., "streak": ... }` | Synchronize user gamification score |
| 14| `/api/payment/create-order`| `POST` | `{ "planId": "...", "returnUrl": "..." }` | VietQR payOS open banking checkout link |
| 15| `/api/payment/check-status`| `GET` | `?orderCode=...` | Poll order payment confirmation |
| 16| `/api/tts` | `GET` | `?text=&lang=` | Edge Neural Text-to-Speech audio stream |
| 17| `/api/geo` | `GET` | None | Client country & region detection |
| 18| `/api/version` | `GET` | None | App version (1.2.4), forceUpdate, release notes |

---

## 6. Porting Execution Workflow for AI Agents

When implementing or porting a feature from `lingua-tube` to `voca_flutter`, follow this standardized 5-step checklist:

1. **Step 1: Inspect the Original Implementation**:
   - Open and read the corresponding component or service in `../lingua-tube/src/app/...`.
   - Take note of state signals, UX nuances, edge-cases, audio playback, and error fallbacks.
2. **Step 2: Check & Extend Models**:
   - Verify that `lib/models/voca_models.dart` contains all required JSON serialization fields.
   - Maintain flexible deserializers (`e is Map` vs `e is String`).
3. **Step 3: Leverage Theme Tokens & Shared Widgets**:
   - Never hardcode hex values. Use `Theme.of(context).vocaColors` and `VocaTokens`.
   - Reuse existing bottom sheets (`VocaBottomSheet`), level badges (`VocaLevelBadge`), and inputs (`VocaSearchInput`).
4. **Step 4: Implement Reactive Signals**:
   - Place long-lived state in `AppState` or `PlayerCoordinator`.
   - Bind widgets reactively using `Watch((context) => ...)`.
5. **Step 5: Run Verification Commands**:
   - Check analysis: `flutter analyze` (must be 0 errors, 0 warnings).
   - Run unit tests: `flutter test` (must pass 100%).

---

## 7. Development, Build & Verification Commands

### Run Static Analysis
```bash
flutter analyze
```

### Run Unit Tests
```bash
flutter test
```

### Run on macOS Desktop (Instant Metal GPU Testing)
```bash
flutter run -d macos
```

### Run on Android Emulator
```bash
flutter run -d emulator-5554
```
> **Note for Android Emulators**: If starting the emulator manually from CLI, always pass `-gpu host` to enable host GPU hardware acceleration for the Chromium WebView:
> `/Users/huyphan/Library/Android/sdk/emulator/emulator -avd Codex_MeoDex -gpu host`

### Attach to Running App Session
```bash
flutter attach -d emulator-5554
```
