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
- **Design & UX Authority — Strict 1:1 Clone Mandate**: The UI port must **NOT** be an approximation, inspired interpretation, or loosely "faithful" adaptation. It must be an **exact 1:1 pixel-perfect port** of `../lingua-tube`.
- Whenever developing any screen, widget, modal, sheet, or interaction, **always inspect the original Angular template (`.component.html`) and stylesheet (`.component.scss` / `_variables.scss` / `_components.scss`) in `../lingua-tube` and replicate every visual and behavioral detail 1:1**.
- **Shared Data & API Contracts**: Both apps share identical Cloudflare Edge APIs (`https://voca.study`), Supabase schemas (`https://edbkvzviqeulwzcnrrlb.supabase.co`), and grammar database structures.

### Key Technologies
- **Framework**: Flutter 3.47.x / Dart 3.13.x
- **State Management**: `signals_flutter` (directly matching the Angular 19 Signal-first reactivity model)
- **Networking**: `dio` (with mandatory anti-bot `User-Agent` and tokenization payload shaping)
- **Video Playback**: `youtube_player_iframe: ^6.0.2` (headless IFrame player engine backed by `webview_flutter`)
- **Backend & Cloud Persistence**: Supabase (`https://edbkvzviqeulwzcnrrlb.supabase.co`) for Auth, Flashcards, Streaks, Playlists, and Watch History
- **Offline Storage**: `hive_ce` / `hive_ce_flutter` for local caching and deterministic ID resolution

---

## 2. Critical Invariants (Non-Negotiable Rules)

### ⚠️ RULE 1: Strict 1:1 UI Clone Requirement (No "Faithful" Approximations or Generic Material Defaults)
- **Zero Creative Liberties**: AI agents MUST NOT invent novel UI layouts, use default Flutter Material 3 widget paddings/shapes, or provide "roughly similar" or "faithful" adaptations.
- **Direct 1:1 Mapping**: Every Flutter widget tree, bottom sheet, dialog, player control, and list item must be a direct 1:1 port of its corresponding template (`.component.html`) and stylesheet (`.component.scss` / `_components.scss` / `_variables.scss`) in `../lingua-tube`:
  - Preserve exact DOM component hierarchy in Flutter widget trees.
  - Replicate exact CSS dimensions, paddings, margins, border radii (`--border-radius-*`), font sizes (`--text-*`), font weights, line heights, letter spacings, and box shadows.
  - Replicate exact color tokens (Light & Dark modes, including hover, active, disabled, and transparent alpha variants).
  - Replicate exact motion, transitions, cubic-bezier timing functions (`--ease-spring`, `--transition-fast`), and gesture behaviors.
  - *Deliberate Mobile UX Exception*: The Onboarding screen (`lib/ui/onboarding/`) is deliberately built as an ergonomic native mobile flow (one decision per step, horizontal snapping companion carousel, thumb-zone CTAs, and system locale detection) rather than a desktop modal. All Voca theme tokens, level badges, and SM-2 starter loot persist unchanged.

### ⚠️ RULE 2: Mandatory Anti-Bot User-Agent Header
- The Cloudflare Pages edge (`https://voca.study`) strictly enforces Cloudflare bot protection. Generic Dart/HTTP scraper headers return HTTP 403 `{"error":"Access denied: automated requests not allowed","code":"BOT_DETECTED"}`.
- Every outgoing HTTP request from `VocaApiClient` MUST include a valid mobile client User-Agent:
  ```dart
  'User-Agent': 'VocaMobile/1.0.0 (Android; Mobile)' // or iOS equivalent
  ```

### ⚠️ RULE 3: YouTube Player Initialization & Embed Recovery
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

### ⚠️ RULE 4: Flexible Dictionary Model Deserialization
- Upstream dictionary providers format example sentences differently:
  - **Mazii (JA-VI)** returns string arrays: `examples: ["例文 (Dịch nghĩa)"]`.
  - **Jotoba (JA-EN)** returns map arrays: `examples: [{"sentence": "...", "translation": "..."}]`.
- In `lib/models/voca_models.dart`, `DictionaryEntry.fromJson` MUST handle both `e is Map` and `e is String`. Never cast `e as Map<String, dynamic>` unconditionally.

### ⚠️ RULE 5: Signal-First Reactivity with `signals_flutter`
- Match the Angular 19 Signal architecture from `lingua-tube` using `signal()`, `computed()`, `effect()`, and `Watch((context) => ...)`.
- Keep widgets clean, isolated, and reactive without unnecessary `setState()` cascades across global scope.

### ⚠️ RULE 6: Deterministic Offline IDs (Cyrb53 Base36)
- Client-side offline records (vocabulary cards, study logs) MUST generate deterministic remote IDs using Cyrb53 Base36:
  ```dart
  generateDeterministicRecordId([userId, word.toLowerCase(), language]);
  // Cyrb53 Base36: base36(userId + '|' + word + '|' + lang).slice(0, 15)
  ```
- This prevents duplicate records when syncing back to Supabase upon reconnection.

### ⚠️ RULE 7: Sticky Subtitle Display Rule
- Do NOT clear active subtitles immediately on brief timestamp gaps (< 3.0 seconds).
- Subtitles must remain visible on screen until the next cue starts to ensure comfortable reading for learners.

### ⚠️ RULE 8: Two-Tier Dual Subtitle Streaming (< 200ms Seek Latency)
- When seeking or starting playback, DO NOT block the UI waiting for whole-video translations.
- **Tier 1 (Urgent seek micro-batch)**: Dispatch active cue + 2 lookahead cues (`cues[i..i+2]`) to `POST /api/translate/batch` (< 200ms display).
- **Tier 2 (Progressive background stream)**: Stream remaining cues in batches of 40–60 items with exponential backoff on HTTP 429.

### ⚠️ RULE 9: Subtitle Track Selection & Language Mismatch Handling
- When `languageMismatch === true` (video captions exist only in an alternate language), present the Subtitle Track Picker sheet offering:
  1. *Switch Target Language*: View captions in one of `availableLanguages.native`.
  2. *Generate with AI*: Trigger Gladia ASR with `preferAI: true` and Turnstile CAPTCHA to transcribe audio into target learning language.

### ⚠️ RULE 10: Atomic Gamification & Streaks via Supabase RPC
- For streak updates, NEVER do a client-side read-modify-write. Always call the atomic Postgres RPC:
  ```dart
  await supabase.rpc('record_streak_activity', params: {
    'p_user_id': userId,
    'p_activity_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
  });
  ```

### ⚠️ RULE 11: NO Autonomous Git Commits
- AI agents **MUST NOT** run `git commit` autonomously unless the USER explicitly directs you to commit.
- Keep all modifications in the working tree for review.

---

## 3. Design System & Strict 1:1 Visual Fidelity (Pixel-Perfect Clone of Original App)

Every visual style, dimension, typography curve, and component aesthetic MUST be an exact 1:1 port of the design system in `../lingua-tube/src/styles/`:

### 3.1. Color Palette Tokens (`_variables.scss` $\rightarrow$ `lib/config/voca_theme.dart`)

| Token | Dark Mode (Rich Obsidian) | Light Mode (Crisp Porcelain) | Purpose / Semantic |
| :--- | :--- | :--- | :--- |
| `bgPrimary` | `#0D0F14` | `#F3F4F7` | Scaffold & main background |
| `bgSecondary` | `#13161F` | `#E8EAF0` | Section backgrounds & navigation bars |
| `bgTertiary` | `#191D28` | `#DFE2E8` | Deepened containers & secondary fills |
| `bgCard` | `#181B24` | `#FFFFFF` | Elevated cards, tiles, bottom sheets |
| `bgSurface` | `#1E222D` | `#F8F9FB` | Surface containers & pill chips |
| `bgHover` | `#252A37` | `#E2E5EC` | Hover and active pressed states |
| `borderColor` | `#272D3B` | `#E2E5EC` | Standard subtle borders (1px) |
| `borderColorLight`| `#1F2430` | `#ECEEF2` | Hairline dividers & soft borders |
| `borderColorHover`| `#394256` | `#C5CBD6` | Focused & hovered border accents |
| `textPrimary` | `#F1F3F7` | `#181D27` | High-contrast body text (WCAG AAA) |
| `textSecondary`| `#969EB2` | `#535862` | Secondary descriptions & subtitles |
| `textMuted` | `#7D879F` | `#717680` | Placeholders & timestamps |
| `textTertiary` | `#545C70` | `#9496A1` | Disabled states & faint metadata |
| `textInverse` | `#0D0F14` | `#FFFFFF` | High-contrast inverted text |
| `accentPrimary`| `#FF6B82` (Radiant Coral) | `#E84562` (Strawberry Coral) | Brand signature, active tabs, buttons |
| `accentPrimaryHover`| `#FF8095` | `#D83855` | Button hover & active interaction |
| `accentPrimarySoft` | `rgba(255, 107, 130, 0.12)` | `rgba(232, 69, 98, 0.08)` | Chip background & selected tints |
| `accentSecondary`| `#A78BFA` (Purple) | `#7C3AED` | Secondary action highlights & PRO tier |
| `accentTertiary`| `#FBBF24` (Amber) | `#D97706` | Warning states & special highlights |
| `colorFire` | `#FB923C` | `#EA580C` | Daily streak flame icon & badge |
| `colorDiamond` | `#38BDF8` | `#0284C7` | AI credits & translation quota |
| `colorGrammar` | `#2DD4BF` | `#10B981` | Grammar token span highlight (mint/emerald) |
| `success` | `#4ADE80` | `#22C55E` | Success feedback & known words |
| `warning` | `#FBBF24` | `#F59E0B` | Warning toasts & alerts |
| `error` | `#F87171` | `#EF4444` | Error states & failed embeds |

### 3.2. Spacing, Sizing & Radii Scale (1:1 with CSS Variables)

| CSS Variable | Value in SCSS | Flutter Value (`double`) | Usage |
| :--- | :--- | :--- | :--- |
| `--space-2xs` | `0.25rem` | `4.0` | Micro spacing, icon gaps |
| `--space-xs` | `0.5rem` | `8.0` | Compact gaps, chip padding |
| `--space-sm` | `0.75rem` | `12.0` | Default element padding |
| `--space-base` | `1.0rem` | `16.0` | Standard card & screen padding |
| `--space-md` | `1.25rem` | `20.0` | Section spacing, mobile horizontal padding |
| `--space-lg-sm`| `1.5rem` | `24.0` | Header padding & modal insets |
| `--space-lg` | `2.0rem` | `32.0` | Large section dividers |
| `--space-xl` | `3.0rem` | `48.0` | Empty states, bottom spacing |
| `--border-radius-xs`| `4px` | `4.0` | Tooltips, mini tags |
| `--border-radius-sm`| `8px` | `8.0` | Small action buttons, menu items |
| `--border-radius` | `10px` | `10.0` | Compact cards, level badges |
| `--border-radius-md`| `12px` | `12.0` | Standard buttons, dialog boxes |
| `--border-radius-lg`| `16px` | `16.0` | Standard cards, video containers |
| `--border-radius-xl`| `20px` | `20.0` | Mobile cards, bottom sheet top corners |
| `--border-radius-2xl`| `24px` | `24.0` | Featured hero cards |
| `--border-radius-pill`| `999px` | `999.0` (`BorderRadius.circular(999)`) | Filter chips, search bar, active pills |
| `--btn-height-xs`| `28px` | `28.0` | Micro inline buttons |
| `--btn-height-sm`| `32px` | `32.0` | Compact buttons (retry, clear) |
| `--btn-height-md`| `38px` | `38.0` | Standard primary & secondary buttons |
| `--btn-height-lg`| `44px` | `44.0` | Big CTAs & modal submission buttons |
| `--bottom-nav-height`| `5.0rem` (`80dp`)| `80.0` | Material 3 Navigation Bar height |
| `--touch-target-min`| `48px` | `48.0` | Minimum tap target for mobile accessibility |

### 3.3. Typography Scale & Fonts

The font family hierarchy is `'Nunito', 'Quicksand', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`. For CJK text: Japanese (`'Kosugi Maru'`, `'Noto Sans JP'`), Chinese (`'Noto Sans SC'`), Korean (`'Noto Sans KR'`).

| Token | Size | Line Height | Weight | Flutter `TextStyle` Spec |
| :--- | :--- | :--- | :--- | :--- |
| `--text-2xs` | `0.6875rem` (`11px`) | `1.2` | `500` / `600` | `fontSize: 11.0, height: 1.2, fontWeight: FontWeight.w500` |
| `--text-xs` | `0.75rem` (`12px`) | `1.3` | `500` / `600` | `fontSize: 12.0, height: 1.3, fontWeight: FontWeight.w500` |
| `--text-sm` | `0.8125rem` (`13px`) | `1.35`| `500` / `600` | `fontSize: 13.0, height: 1.35, fontWeight: FontWeight.w500` |
| `--text-base` | `0.875rem` (`14px`) | `1.4` | `500` / `550` | `fontSize: 14.0, height: 1.4, fontWeight: FontWeight.w500` |
| `--text-md` | `1.0rem` (`16px`) | `1.45`| `600` | `fontSize: 16.0, height: 1.45, fontWeight: FontWeight.w600` |
| `--text-lg` | `1.125rem` (`18px`) | `1.4` | `600` / `700` | `fontSize: 18.0, height: 1.4, fontWeight: FontWeight.w600` |
| `--text-xl` | `1.25rem` (`20px`) | `1.35`| `700` | `fontSize: 20.0, height: 1.35, fontWeight: FontWeight.w700` |
| `--text-2xl` | `1.5rem` (`24px`) | `1.3` | `700` / `800` | `fontSize: 24.0, height: 1.3, fontWeight: FontWeight.w700` |
| `--text-3xl` | `1.75rem` (`28px`) | `1.25`| `800` | `fontSize: 28.0, height: 1.25, fontWeight: FontWeight.w800` |

### 3.4. Standard Educational Level Badges (5 Tiers — 1:1 Color Matrix)

Rendered dynamically via `LevelColorInfo.forLevel(level, isDark: ...)`:

| Tier | Levels Covered | Dark Mode (Background / Border / Text) | Light Mode (Background / Border / Text) |
| :--- | :--- | :--- | :--- |
| **Beginner** | JLPT N5, HSK 1, TOPIK 1, CEFR A1 | `rgba(88, 175, 255, 0.14)` / `rgba(88, 175, 255, 0.25)` / `#9BCEFF` | `#E6F2FF` / `rgba(14, 96, 184, 0.20)` / `#0E60B8` |
| **Elementary** | JLPT N4, HSK 2, TOPIK 2, CEFR A2 | `rgba(56, 217, 238, 0.14)` / `rgba(56, 217, 238, 0.25)` / `#67E8F9` | `#E2F6F9` / `rgba(8, 115, 130, 0.20)` / `#087382` |
| **Intermediate**| JLPT N3, HSK 3-4, TOPIK 3-4, CEFR B1 | `rgba(251, 197, 61, 0.14)` / `rgba(251, 197, 61, 0.25)` / `#FDE068` | `#FEF3D6` / `rgba(139, 87, 0, 0.20)` / `#8B5700` |
| **Upper** | JLPT N2, HSK 5, TOPIK 5, CEFR B2 | `rgba(251, 146, 60, 0.14)` / `rgba(251, 146, 60, 0.25)` / `#FDBA74` | `#FFF0E5` / `rgba(167, 74, 0, 0.20)` / `#A74A00` |
| **Advanced** | JLPT N1, HSK 6, TOPIK 6, CEFR C1-C2 | `rgba(255, 120, 145, 0.14)` / `rgba(255, 120, 145, 0.25)` / `#FFA4B5` | `#FFEBF0` / `rgba(196, 43, 71, 0.20)` / `#C42B47` |

### 3.5. Word Learning Status Badges (1:1 Color Matrix)

| State | Dark Mode (Bg / Border / Text) | Light Mode (Bg / Border / Text) |
| :--- | :--- | :--- |
| **New** | `rgba(255, 120, 145, 0.14)` / `rgba(255, 120, 145, 0.24)` / `#FFA4B5` | `#FFEBF0` / `rgba(196, 43, 71, 0.18)` / `#C42B47` |
| **Learning** | `rgba(251, 197, 61, 0.14)` / `rgba(251, 197, 61, 0.24)` / `#FDE068` | `#FEF3D6` / `rgba(139, 87, 0, 0.18)` / `#8B5700` |
| **Known** | `rgba(88, 175, 255, 0.14)` / `rgba(88, 175, 255, 0.24)` / `#9BCEFF` | `#E6F2FF` / `rgba(14, 96, 184, 0.18)` / `#0E60B8` |
| **Ignored** | `rgba(255, 255, 255, 0.06)` / `rgba(255, 255, 255, 0.08)` / `#8E95AF` | `#E8EAF0` / `rgba(83, 88, 98, 0.16)` / `#535862` |

### 3.6. Shadows & Motion System (1:1 Mapping)

- **Shadows**:
  - `--shadow-sm`: Dark `0 1px 3px rgba(0,0,0,0.4)` / Light `0 1px 2px rgba(0,0,0,0.04), 0 1px 3px rgba(0,0,0,0.03)`
  - `--shadow-md`: Dark `0 4px 10px rgba(0,0,0,0.5)` / Light `0 2px 6px rgba(0,0,0,0.06), 0 4px 12px rgba(0,0,0,0.04)`
  - `--shadow-lg`: Dark `0 10px 24px rgba(0,0,0,0.55)` / Light `0 4px 12px rgba(0,0,0,0.08), 0 8px 24px rgba(0,0,0,0.06)`
  - `--shadow-xl`: Dark `0 20px 32px rgba(0,0,0,0.65)` / Light `0 12px 28px rgba(0,0,0,0.12), 0 4px 12px rgba(0,0,0,0.06)`
- **Animation Timing & Curves**:
  - Fast: `150ms`, `Cubic(0.4, 0.0, 0.2, 1.0)`
  - Normal: `250ms`, `Cubic(0.34, 1.56, 0.64, 1.0)` (Bounce/spring)
  - Spring: `500ms`, `Cubic(0.16, 1.0, 0.3, 1.0)` (`ease-spring`)

---

## 4. Component-by-Component 1:1 Porting Specifications

When porting or updating any component, verify its visual and functional parity against the original Angular template:

### 4.1. Spotlight Search Input (`spotlight-bar` / `VocaSearchInput`)
- **Structure**: Single pill-shaped container (`height: 38px` or `44px`, `border-radius: 999px`, `background: bgSurface`, `border: 1px solid borderColor`).
- **Left Element**: Search / Link icon (`18px`, color `textMuted`).
- **Input**: Expandable text field, placeholder `Paste YouTube link or search videos...` (`textMuted`), no borders, no underline.
- **Right Action Buttons**:
  - When query is non-empty: Circular clear button (`x` icon, `14px`) + Action button (`btn btn-primary` with `Load` or `Search` label).
  - When query is empty: Paste from clipboard button (`clipboard-check` icon, `15px` + `Paste` label).

### 4.2. Video Player & Overlay Controls (`video-player.component.html`)
- **16:9 Player Viewport**: Clamped with `AspectRatio(aspectRatio: 16 / 9)`.
- **Center Controls**:
  - Big play/pause button: `64px` circle, semi-transparent frosted background (`rgba(0,0,0,0.6)`), animated icon pop on toggle.
  - Replay button: Displayed when `isEnded == true` (`rotate-ccw` icon).
  - Playlist skip buttons: `44px` circles with `skip-back` and `skip-forward` icons when a playlist is active.
- **Double-Tap Seek Feedback**: Left/right zone double-tap initiates seek feedback overlay with chevron and `+5s` / `+10s` accumulator pill text with pulse animation.
- **Top OSD Feedback Pills**: Transient floating pill at the top of the video showing playback speed changes (e.g. `1.25x`) and caption toggles.
- **Vignette Gradient**: `linear-gradient(to top, rgba(0,0,0,0.7) 0%, transparent 40%, transparent 60%, rgba(0,0,0,0.7) 100%)` visible when controls are active.
- **Mini Progress Bar**: 2px hairline accent progress bar along the bottom when controls are hidden.

### 4.3. Video Header & Video Bottom Bar (`video-header` & `video-bottom-bar`)
- **Video Header**:
  - Two-line title (`16px`, bold, ellipsis), channel name (`13px`, `textSecondary`), level badge (sm size, opens level modal on tap).
  - Header actions: Subtitle track picker button, share button, and close video button (`x`).
- **Video Bottom Bar**:
  - Scrubber progress bar: Played bar (`accentPrimary`), buffered bar (`textMuted` with opacity), scrub thumb with drag tooltip.
  - Controls row: Time readout (`13px`, `currentTime / totalDuration`), dual subtitles toggle (`languages` icon with active dot), player settings gear (`settings` icon), miniplayer toggle (`miniplayer` icon), fullscreen toggle (`fullscreen` icon).
  - Player Settings Sheet: Speed selector (0.5x to 2.0x), Subtitle font size (Small, Medium, Large, Extra Large), Dual subtitle target language selector with circular country flags, Reading mode selector (Off, Furigana/Pinyin, Romaji), Grammar mode toggle, Sleep timer.

### 4.4. Interactive Subtitle Display (`subtitle-display.component.html`)
- **Ruby Furigana & Pinyin**:
  - Japanese: Furigana text positioned directly above Kanji tokens.
  - Chinese: Pinyin with tone marks positioned above Hanzi.
  - Romaji: English romanization option.
- **Interactive Word Tokens**:
  - Every word token is individually tappable.
  - Visual status classes: `word--new` (coral border/bg tint), `word--learning` (amber border/bg tint), `word--known` (blue border/bg tint), `word--saved` (checkmark/tint).
  - Grammar highlights: Mint/emerald underline and soft glow when token matches a grammar pattern.
- **Sticky Cue Display**: Maintains subtitle visibility over gaps under 3.0 seconds to prevent distracting screen flickering.
- **Dual Subtitles Secondary Line**: Rendered directly beneath target subtitles in `13px` italicized `textSecondary`.
- **Coachmark Banner**: Dismissible educational banner ("Tap any word to translate & save") with lightbulb icon.

### 4.5. Transcript View & Video Page Sidebar
- **Tab Switcher**: Segmented pill control switching between `Words` and `Grammar` (or `Playlist`, `Words`, `Grammar`).
- **Auto-Scrolling Cue List**: Active cue highlighted with accent left border (3px) and luminous background (`accentPrimarySoft`).
- **Resume Auto-Scroll Button**: Floating pill appearing at the bottom when learner scrolls away from the currently playing timestamp.
- **Search Transcript**: Sticky header search input filtering cues in real time with keyword highlights.

### 4.6. Docked Mobile Miniplayer Bar
- **Dimensions**: `60dp` height docked above navigation bar (or bottom edge).
- **Layout**: 16:9 video thumbnail on left (`80px` width), title and channel text in center with marquee ellipsis, circular play/pause and dismiss (`x`) buttons on right.
- **Bottom Hairline Progress Track**: Full-width `1.5px` progress line (`accentPrimary`) along the bottom edge of the miniplayer card.
- **Interaction**: Tapping anywhere on the miniplayer smoothly expands the player back to full view.

### 4.7. Dictionary Bottom Sheet (`dict-modal` / `word-popup`)
- **Unified Header**: Drag handle pill + close button (`x`).
- **Headword Section**: Large headword (`24px`, bold), phonetic pronunciation (hiragana/pinyin/ipa), speaker icon button triggering Edge TTS audio playback.
- **Target Language Selector**: Dropdown with circular country flags and "Translate All" button.
- **Level & POS Badges**: Localized Part-of-Speech tag pill + Level badge (JLPT N5–N1, HSK 1–6, TOPIK 1–6).
- **Sense Definitions List**: Multi-sense tab pills (Sense 1, Sense 2) when applicable, numbered definitions with clear translations.
- **Authentic Example Sentences**: Bilingual sentence cards with clickable token lookups.
- **Bottom Action Footer**: Sticky primary CTA button: `+ Save Word` (or `Saved` state with SM-2 review interval status).

### 4.8. Grammar Bottom Sheet (`grammar-modal` / `grammar-popup`)
- **Header**: Pattern name (`20px`, bold), JLPT/CEFR level pill badge, brief meaning overview.
- **Formation Box**: Monospace formula container (`bgSurface`, `border: 1px solid borderColor`) showing structure rules (e.g. `V-te + もいい`).
- **Explanation & Nuance**: Section explaining nuance, common mistakes, and register (formal/casual).
- **Authentic Video Examples**: Real examples from YouTube with bilingual translations and ruby annotations.

### 4.9. Study Deck Screen (`study-page.component.html`)
- **Progress Header**: Review progress pill (e.g. `Card 3 / 15`), exit button, flip hint.
- **3D Card Flip Animation**: Smooth horizontal perspective flip (`Transform` with `Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(...)`):
  - **Front**: Headword in center, optional hide-reading toggle, sentence context with cloze blank.
  - **Back**: Phonetic reading, definition, audio auto-play, full sentence context with highlight.
- **4 SM-2 Grading Buttons**:
  - `Again` (< 1m, red text & border)
  - `Hard` (12h, amber text & border)
  - `Good` (1d, blue text & border)
  - `Easy` (4d, green text & border)

### 4.10. Gamification & System Dialogs
- **Streak Dialog**: Daily flame icon (`colorFire`), current streak count, 7-day calendar row with active day checkmarks, freeze streak status.
- **AI Credits / Diamonds Dialog**: Diamond count (`diamonds / maxDiamonds`), regeneration countdown timer, upgrade CTA button.
- **Level & Achievements Dialog**: RPG Rank tier crest (Stone, Bronze, Silver, Gold, Platinum, Diamond, Master, Grandmaster, Mythic), total XP, level progress bar, claimable rewards notification dot.
- **Pro Upgrade Dialog**: VietQR payOS open banking QR code, plan features list, payment confirmation polling.

### 4.11. Bottom Navigation Bar (`main_shell.dart`)
- **Material 3 Navigation Bar**: `80dp` height with 5 persistent tabs:
  1. `Watch` (`play-circle`) — includes animated 3-bar equalizer "Now Playing" icon when video is active
  2. `Review` (`graduation-cap`)
  3. `Vocabulary` (`book-open`)
  4. `Playlists` (`list-video`)
  5. `History` (`history`)
- **Active Indicator**: Horizontal pill shape (`accentPrimarySoft` background, `accentPrimary` icon & text).

---

## 5. Original App (`lingua-tube`) $\rightarrow$ Flutter (`voca_flutter`) File Mapping

| Original Web File (`lingua-tube`) | Flutter Destination (`voca_flutter`) | 1:1 Port Responsibility |
| :--- | :--- | :--- |
| `src/styles/_variables.scss` | `lib/config/voca_theme.dart` | Exact color tokens, spacing scale, radii, typography |
| `src/app/components/sidebar/` | `lib/ui/shell/main_shell.dart` | Bottom nav bar (80dp), active pills, equalizer indicator |
| `src/app/features/video/video-page/` | `lib/ui/video/video_player_screen.dart` | Page layout, feed carousel, sidebar tabs |
| `src/app/features/video/video-player/video-player.component.*` | `lib/ui/video/video_player_screen.dart` | 16:9 player, touch gestures, OSD pills, error states |
| `src/app/features/video/video-player/components/video-header/` | `lib/ui/video/video_header.dart` | Video title, channel, level badge, header actions |
| `src/app/features/video/video-player/components/center-controls/`| `lib/ui/video/center_controls.dart` | Big play/pause, playlist skip buttons, seek feedback |
| `src/app/features/video/video-player/components/video-bottom-bar/`| `lib/ui/video/video_bottom_bar.dart` | Scrubber, time display, dual subs, speed, settings |
| `src/app/features/video/subtitle-display/` | `lib/ui/widgets/interactive_subtitle_view.dart`| Ruby furigana, pinyin, word states, grammar underline |
| `src/app/features/video/video-page/video-page.component.html` (sidebar)| `lib/ui/video/transcript_view.dart` | Transcript cues, auto-scroll, search, resume pill |
| `src/app/features/video/miniplayer/` | `lib/ui/video/miniplayer_bar.dart` | Docked 60dp miniplayer, thumbnail, play/pause, dismiss |
| `src/app/features/dictionary/dict-modal.component.*` | `lib/ui/sheets/dictionary_bottom_sheet.dart` | Word lookup, TTS speaker, POS/Level badges, Save CTA |
| `src/app/features/grammar/grammar-modal.component.*` | `lib/ui/sheets/grammar_bottom_sheet.dart` | Grammar rule, formula box, authentic video examples |
| `src/app/features/study/study-page.component.*` | `lib/ui/study/study_deck_screen.dart` | 3D flip card, SM-2 Again/Hard/Good/Easy review buttons |
| `src/app/features/vocabulary/vocabulary-list.component.*` | `lib/ui/vocabulary/vocabulary_screen.dart` | Filter chips, search bar, word cards, level filters |
| `src/app/features/playlist/` & `history/` | `lib/ui/library/library_screen.dart` | YouTube-style video cards, progress bars, playlist grid |
| `src/app/components/streak-dialog/` | `lib/ui/sheets/streak_dialog.dart` | Streak flame counter, 7-day calendar checkmarks |
| `src/app/components/ai-credits-dialog/` | `lib/ui/sheets/ai_credits_dialog.dart` | AI diamonds quota, regeneration timer, upgrade CTA |
| `src/app/components/achievements-dialog/` | `lib/ui/sheets/achievements_dialog.dart` | RPG rank tiers, XP counter, claimable rewards |
| `src/app/components/settings-sheet/` | `lib/ui/settings/settings_screen.dart` | Learning language, furigana toggle, theme mode |

---

## 6. Master Edge API Specification (`https://voca.study/api/*`)

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

## 7. Porting Execution Workflow for AI Agents

When implementing or modifying any UI in `voca_flutter`, follow this strict 5-step checklist:

1. **Step 1: Inspect the Original Angular Code**:
   - Open and inspect the matching `.component.html` and `.component.scss` in `../lingua-tube/src/app/...`.
   - Read the exact HTML DOM hierarchy, CSS class rules, and CSS custom property references.
2. **Step 2: Map to Flutter Widgets 1:1**:
   - Translate the HTML hierarchy directly into Flutter widget trees.
   - Use exact tokens from `voca_theme.dart` (colors, paddings, border radii, typography).
   - Do NOT use generic Material 3 styles or make approximate guesses.
3. **Step 3: Connect Reactive Signals**:
   - Map Angular Signals (`signal`, `computed`, `effect`) directly to `signals_flutter` (`signal()`, `computed()`, `effect()`, `Watch`).
   - Keep widget builds granular and isolated.
4. **Step 4: Verify 1:1 Visual Parity**:
   - Compare layouts, spacing, font weights, colors, and animations against `../lingua-tube`.
   - Ensure interactive states (hover, press, active, disabled) match the web app 1:1.
5. **Step 5: Run Verification Commands**:
   - Run `flutter analyze` (must be 0 errors, 0 warnings).
   - Run `flutter test` (must pass 100%).

---

## 8. Development, Build & Verification Commands

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
