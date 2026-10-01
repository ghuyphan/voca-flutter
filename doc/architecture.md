# Voca Flutter — Architecture & System Map

This document outlines the structural design, component hierarchy, state management paradigm, and data flows of the **Voca Flutter** application.

---

## 1. System Topology Overview

Voca Flutter uses a **Dual-Backend Architecture**:
1. **Public Edge Services (Stateless / Compute-Heavy)**: Cloudflare Pages Functions edge network at `https://voca.study/api/*` handles transcript fetching, ASR orchestration, morphological tokenization, multi-source dictionary lookups, and video recommendations.
2. **User Data Persistence (Stateful / Cloud BaaS)**: Supabase PostgreSQL at `https://edbkvzviqeulwzcnrrlb.supabase.co` handles user authentication (Google OAuth), spaced repetition flashcards, daily practice streaks, custom playlists, and watch history.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           VOCA FLUTTER APP                              │
│  [ UI Shell ] ──► [ Signals State ] ──► [ Core Services & Local Repos ] │
└──────────────────┬───────────────────────────────────┬──────────────────┘
                   │                                   │
                   │ HTTP REST (Dio Client)            │ Supabase SDK / REST
                   ▼                                   ▼
   ┌───────────────────────────────┐   ┌───────────────────────────────┐
   │      Cloudflare Edge API      │   │         Supabase BaaS         │
   │      https://voca.study       │   │  https://edbkvzviqeulwzcnrrlb │
   │                               │   │  .supabase.co                 │
   │  • /api/transcript            │   │  • Auth (Google OAuth & JWT)  │
   │  • /api/tokenize-batch/:lang  │   │  • vocabulary (SM-2 Cards)    │
   │  • /api/dict (Multi-source)   │   │  • streaks (record_streak_rpc)│
   │  • /api/recommended-videos    │   │  • playlists & history        │
   │  • /api/diamonds & /version   │   │  • profiles & gamification    │
   └───────────────────────────────┘   └───────────────────────────────┘
```

---

## 2. State Management (`signals_flutter`)

Voca Flutter uses `signals_flutter` (Signals pattern) to achieve identical reactive paradigms as the web version's Angular 19 Signals architecture.

### Benefits
- **Fine-Grained Updates**: Only widgets wrapped in `Watch((context) => ...)` rebuild when their observed signal value changes.
- **No Boilerplate**: No event dispatchers, reducers, or complex `ChangeNotifier` state sync.
- **Computed Derivations**: Instant derived state via `computed()`.

### Key Signal Stores
1. **`AppState` (`lib/state/app_state.dart`)**:
   - `activeLanguage`: Current target learning language (`ja`, `zh`, `ko`, `en`).
   - `userProfile`: Current authenticated Supabase user profile.
   - `themeMode`: UI theme preference (Dark by default).
2. **`VideoPlayerController` (`lib/state/player_state.dart`)**:
   - `currentTime`: Floating-point video playback time in seconds (updated via player ticker).
   - `cues`: Loaded list of `SubtitleCue` objects.
   - `activeCue`: Computed signal returning the currently active subtitle cue based on `currentTime`.
   - `activeGrammarMatches`: Grammar patterns identified in the active cue.
   - `languageMismatch`: Boolean indicating whether requested native captions are unavailable.
   - `isLoading` & `statusMessage`: Feedback during network tokenization and ASR polling.

---

## 3. Offline-First Repository Pattern

Mobile connectivity can be intermittent. Voca Flutter ensures flashcard study, saved words, and recent history remain functional offline:

1. **Deterministic Cyrb53 Remote IDs**:
   When a user adds a word to their vocabulary offline, the remote ID is generated deterministically:
   $$\text{ID} = \text{base36}(\text{cyrb53}(\text{userId} + "|" + \text{word} + "|" + \text{lang})).\text{slice}(0, 15)$$
   This ensures that concurrent sync or offline queue flushes never produce duplicate rows in Supabase.
2. **Local Caching Layer**:
   Entities are stored locally in Hive boxes (`hive_ce`), enabling instant cold starts and offline study deck reviews.
3. **Optimistic UI Updates**:
   Flashcard reviews immediately update local SM-2 intervals and ease factors; network synchronization to Supabase proceeds asynchronously in the background.

---

## 4. UI Layer Architecture

```
lib/ui/
├── main_shell.dart              # Persistent Scaffold with Material 3 NavigationBar
├── explore/
│   └── explore_screen.dart      # Language selector, CEFR/JLPT filter pills, video card grid
├── video/
│   └── video_player_screen.dart # 16:9 YouTube surface, error fallback banner, subtitle area
├── study/
│   └── study_deck_screen.dart   # SM-2 Flashcard flip animation, rating buttons (Again/Hard/Good/Easy)
├── vocabulary/
│   └── vocabulary_screen.dart   # Filterable & searchable saved words list
├── widgets/
│   └── interactive_subtitle_view.dart # Custom Ruby/Furigana text, Pinyin, and grammar spans
└── sheets/
    ├── dictionary_bottom_sheet.dart   # Multi-source dictionary definition modal
    └── grammar_bottom_sheet.dart      # Grammar pattern explanation & example sentences
```
