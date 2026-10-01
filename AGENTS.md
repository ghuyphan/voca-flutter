# Voca Flutter — AI Agent Instructions & Architectural Guide (AGENTS.md)

This document provides essential instructions, architectural design, codebase maps, critical invariants, and development workflows for AI coding assistants working in the **Voca Flutter** mobile repository (`voca_flutter`).

---

## 1. Executive Summary & Purpose

**Voca Flutter** is the cross-platform mobile application (Android & iOS) for Voca (formerly LinguaTube). It provides language learners (specifically **Japanese**, **Chinese**, **Korean**, and **English**) with an interactive immersion experience using authentic YouTube videos:
- Synchronized interactive subtitles with Ruby/Furigana, Pinyin, and Romaji.
- Morphological tokenization via Edge Cloudflare Functions.
- Client-side grammar pattern detection (JLPT N5–N1, HSK 1–6, TOPIK 1–6, CEFR A1–C2).
- Multi-source dictionary lookups (Mazii, Jotoba, Naver, MDBG).
- SM-2 Spaced Repetition (SRS) vocabulary deck with deterministic offline-first sync.
- Dual backend architecture: Cloudflare Edge (`voca.study`) for public linguistics/video APIs, and Supabase for cloud user persistence.

### Key Technologies
- **Framework**: Flutter 3.47.x / Dart 3.13.x
- **State Management**: `signals_flutter` (matching the Angular 19 Signal-first reactivity model)
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
- Match the Angular 19 Signal architecture using `signal()`, `computed()`, and `Watch((context) => ...)`.
- Keep widgets clean, isolated, and reactive without unnecessary `setState()` cascades across global scope.

### ⚠️ RULE 5: Deterministic Offline IDs (Cyrb53 Base36)
- Client-side offline records (vocabulary cards, study logs) MUST generate deterministic remote IDs using Cyrb53 Base36 (`base36(userId + '|' + word + '|' + lang).slice(0, 15)`).
- This prevents duplicate records when syncing back to Supabase upon reconnection.

### ⚠️ RULE 6: Sticky Subtitle Display Rule
- Do NOT clear active subtitles immediately on brief timestamp gaps (< 3.0 seconds).
- Subtitles must remain visible on screen until the next cue starts to ensure comfortable reading for learners.

---

## 3. Architecture & System Map

```
┌────────────────────────────────────────────────────────────────────────┐
│                        VOCA FLUTTER ARCHITECTURE                       │
└────────────────────────────────────────────────────────────────────────┘

 [ UI LAYER: Flutter Presentation ]
    ├── Video Feature:       VideoPlayerScreen (YoutubePlayer + Error Fallback Banner)
    │                        InteractiveSubtitleView (Ruby furigana, pinyin, romaji)
    │                        DictionaryBottomSheet & GrammarBottomSheet
    │
    ├── Study & Flashcards:  StudyDeckScreen (SM-2 SRS Flip Cards, Again/Hard/Good/Easy)
    │                        VocabularyScreen (Saved words list & search)
    │
    ├── Discovery:           ExploreScreen (Language selector, level pills, video cards)
    │
    └── Navigation Shell:    MainShell (Persistent bottom navigation: Explore, Study, Vocab)

          │
          │ Reactive Signals (signals_flutter)
          ▼
 [ STATE LAYER ]
    ├── AppState:            Active language, user auth profile, global UI signals
    └── VideoPlayerController: Current playback time, active cue, grammar matches,
                               subtitle batch tokenization queue

          │
          │ Services & Engines
          ▼
 [ CORE SERVICES ]
    ├── VocaApiClient:       Dio client -> Cloudflare Edge (https://voca.study/api/*)
    │                        - Transcript Orchestrator (R2 -> Supadata -> Gladia ASR)
    │                        - Batch tokenization (/api/tokenize-batch/:lang)
    │                        - Multi-source dictionary (/api/dict)
    │                        - Recommendations (/api/recommended-videos)
    │
    ├── GrammarEngine:       Client-side pattern matcher loading 2,400+ bundled rules:
    │                        assets/grammar/grammar_{ja,zh,ko,en}.json
    │
    ├── SrsService:          SuperMemo-2 (SM-2) spaced repetition algorithm
    │
    └── SupabaseService:     Supabase client -> https://edbkvzviqeulwzcnrrlb.supabase.co
                             - Google OAuth & Session Management
                             - Flashcards sync (vocabulary table)
                             - Atomic streak updates (record_streak_activity RPC)
                             - Watch history & playlists
```

---

## 4. Directory Structure

```
voca_flutter/
├── AGENTS.md                  # This file (AI agent guidance, rules & architecture)
├── README.md                  # Public overview
├── pubspec.yaml               # Dependencies and asset declarations
├── analysis_options.yaml      # Static analysis lints
│
├── assets/                    # Bundled offline assets
│   ├── grammar/               # Extracted grammar rules
│   │   ├── grammar_ja.json    # Japanese JLPT N5–N1 rules
│   │   ├── grammar_zh.json    # Chinese HSK 1–6 rules
│   │   ├── grammar_ko.json    # Korean TOPIK 1–6 rules
│   │   └── grammar_en.json    # English CEFR A1–C2 rules
│   └── i18n/                  # UI localization strings (en, ja, ko, vi, zh)
│
├── lib/
│   ├── main.dart              # App bootstrap, Supabase initialization, AppState injection
│   ├── models/
│   │   └── voca_models.dart   # Token, SubtitleCue, GrammarPattern, Flashcard, DictEntry
│   ├── services/
│   │   ├── voca_api_client.dart  # Edge API client (Dio with User-Agent & retry)
│   │   ├── grammar_engine.dart   # Local regex & token matcher
│   │   ├── srs_service.dart      # SM-2 Flashcard calculation engine
│   │   └── supabase_service.dart # Supabase BaaS repository
│   ├── state/
│   │   ├── app_state.dart     # Global signals (language, profile, theme)
│   │   └── player_state.dart  # Video playback & sticky subtitle controller
│   ├── ui/
│   │   ├── main_shell.dart    # Scaffold with persistent BottomNavigationBar
│   │   ├── explore/           # ExploreScreen & video recommendation cards
│   │   ├── video/             # VideoPlayerScreen & controls
│   │   ├── study/             # StudyDeckScreen (SRS flashcard review)
│   │   ├── vocabulary/        # VocabularyScreen (saved words)
│   │   ├── widgets/           # InteractiveSubtitleView, RubyText, TokenChip
│   │   └── sheets/            # DictionaryBottomSheet, GrammarBottomSheet
│   └── utils/
│       └── cyrb53_hasher.dart # Deterministic Base36 ID hasher
│
└── test/
    └── voca_core_test.dart    # Unit tests for Cyrb53, SM-2 SRS, and token deserialization
```

---

## 5. Development & Testing Commands

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
