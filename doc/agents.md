# Voca Flutter — AI Agent Instructions & Architectural Guide (doc/agents.md)

This document is the mirror of `AGENTS.md` located in the root of `voca_flutter`. All AI coding assistants working in this repository MUST follow these rules without exception.

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

## 3. Fast Verification Checklist
Before completing any task in `voca_flutter`:
1. Run `flutter analyze` $\rightarrow$ must report **0 issues**.
2. Run `flutter test` $\rightarrow$ all tests must pass.
3. Check `git status` $\rightarrow$ ensure no unintended files or binaries were generated.
