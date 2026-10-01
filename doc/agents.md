# Voca Flutter — AI Agent Instructions & Critical Invariants (doc/agents.md)

This document is the mirror of `AGENTS.md` located in the root of `voca_flutter`. All AI coding assistants (Antigravity, Cursor, Claude Code, GitHub Copilot) MUST follow these rules without exception.

---

## 1. Critical Invariants (Non-Negotiable Rules)

### ⚠️ RULE 1: Mandatory Anti-Bot User-Agent Header
- The Cloudflare Pages edge (`https://voca.study`) strictly enforces bot protection. Generic Dart/HTTP scraper headers return HTTP 403 `{"error":"Access denied: automated requests not allowed","code":"BOT_DETECTED"}`.
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

### ⚠️ RULE 7: NO Autonomous Git Commits
- AI agents **MUST NOT** run `git commit` autonomously unless the USER explicitly directs you to commit.
- Keep changes in the working tree for user review.

---

## 2. Fast Verification Checklist
Before completing any task in `voca_flutter`:
1. Run `flutter analyze` $\rightarrow$ must report **0 issues**.
2. Run `flutter test` $\rightarrow$ all tests must pass.
3. Check `git status` $\rightarrow$ ensure no unintended files or binaries were generated.
