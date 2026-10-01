# Voca Flutter — Features & Linguistic Systems Deep Dive

This document details the core learner-facing features of **Voca Flutter**, including the interactive subtitle renderer, client-side grammar pattern engine, SM-2 Spaced Repetition flashcard system, and YouTube player integration.

---

## 1. Interactive Subtitle Engine (`InteractiveSubtitleView`)

Voca's primary differentiator is turning passive video listening into active, interactive immersion.

### A. Ruby & Furigana Annotations
- **Japanese**: For kanji tokens with non-empty `reading`, hiragana is positioned above the kanji base text using a stacked vertical alignment (`Column` with `MainAxisSize.min`).
- **Chinese**: Pinyin tone marks are positioned above Hanzi characters.
- **Korean & English**: Text displays cleanly with optional Romanization or IPA.

```
       ゆめ
     [  夢  ] [ ならば ] [ どれほど ] [ よかった ] [ でしょう ]
        Noun     Part.       Adv.         Verb        Aux.
```

### B. Sticky Subtitle Display Rule
In normal subtitle streams, brief pauses in speech (e.g. 0.5s – 2.0s between sentences) can cause subtitles to flash or disappear prematurely, straining learner comprehension.
- **Rule**: If the gap between the current cue's `end` time and the next cue's `start` time is less than **3.0 seconds**, the current subtitle cue remains visible on screen until the next cue begins.

### C. Low-Latency Seek Micro-Batches
When a learner scrubs or jumps in a video:
- An immediate urgent micro-batch translates the active cue and the immediate next 2 cues (`cues[i..i+2]`), rendering translated captions within **< 200ms**.
- Background chunked batch translation continues concurrently in the background without freezing the UI.

---

## 2. Client-Side Grammar Pattern Matcher (`GrammarEngine`)

Rather than querying a remote server for grammar analysis on every frame, Voca bundles **2,400+ compiled grammar patterns** into local JSON assets:
- `assets/grammar/grammar_ja.json` (JLPT N5–N1)
- `assets/grammar/grammar_zh.json` (HSK 1–6)
- `assets/grammar/grammar_ko.json` (TOPIK 1–6)
- `assets/grammar/grammar_en.json` (CEFR A1–C2)

### Matching Capabilities
1. **Multi-Token Sliding Window**: Matches compound patterns (e.g. `わけにはいかない`, `〜にすぎない`).
2. **Lemma / Dictionary Form Matching**: Uses `token.baseForm` to recognize conjugated verb patterns (e.g. `食べた後で` matches `〜た後で`).
3. **Split Correlatives (Chinese)**: Matches paired structures across distance (e.g. `虽然...但是...`, `不但...而且...`).
4. **Interactive Highlights**: Matched grammar spans are underlined in amber. Tapping any grammar token pauses playback and opens the `GrammarBottomSheet` with detailed grammar rules, structure breakdown, and bilingual examples.

---

## 3. SM-2 Spaced Repetition System (SRS)

Voca implements the SuperMemo-2 (SM-2) algorithm for vocabulary retention:

### Quality Rating Scale
- **Again (1)**: Complete blackout. Interval resets to 1 day; repetitions reset to 0.
- **Hard (3)**: Correct response with significant hesitation. Interval scales slowly.
- **Good (4)**: Correct response after normal recall.
- **Easy (5)**: Perfect instant recall. Interval increases significantly.

### Mathematical Formulation
When rating $q \ge 3$:
$$\text{EF}' = \max\left(1.30, \text{EF} + (0.1 - (5 - q) \cdot (0.08 + (5 - q) \cdot 0.02))\right)$$

$$\text{Interval}(n) = \begin{cases} 
1 \text{ day} & n = 1 \\ 
6 \text{ days} & n = 2 \\ 
\text{round}(\text{Interval}(n-1) \cdot \text{EF}') & n > 2 
\end{cases}$$

When rating $q < 3$:
$$\text{Interval} = 1, \quad \text{Repetitions} = 0, \quad \text{EF unchanged}$$

---

## 4. YouTube Player Integration & Error Recovery

### Package Architecture
Powered by `youtube_player_flutter: ^10.0.1` and `webview_flutter`.

### Critical Implementation Rules
1. **Avoid Controller `key`**:
   Never use `YoutubePlayerController.fromVideoId(videoId: ...)` or pass a non-null `key`. In `youtube_player_iframe`, a non-null `key` triggers `_PlayerLoadingOverlay`, which pins a full-screen thumbnail image over the player during `unStarted` states and intercepts touch events.
   **Correct Initialization**:
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

2. **Preventing Error 152-4**:
   Set `origin: 'https://www.youtube-nocookie.com'` and `privacyEnhancedMode: true`. This resolves the origin mismatch error common in mobile WebViews.

3. **Syndication Fallback (Error 150/152/101)**:
   Official music videos (e.g. Sony, Stone Music, avex) often have syndication embedding disabled by copyright owners. When detected:
   - The player surfaces a clear notification: *"Playback Restricted by Owner"*.
   - Provides a **"Watch on YouTube"** button (`url_launcher`) so learners can watch the video externally while continuing to study the transcript and vocabulary in Voca.
