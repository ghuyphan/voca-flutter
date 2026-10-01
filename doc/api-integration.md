# Voca Flutter — API & Supabase Integration Guide

This document provides complete reference specifications for integrating with the **Cloudflare Edge API** (`https://voca.study/api/*`) and the **Supabase BaaS** (`https://edbkvzviqeulwzcnrrlb.supabase.co`).

---

## 1. Cloudflare Edge API (`https://voca.study`)

All edge endpoints are hosted on Cloudflare Pages Functions.

### ⚠️ Mandatory Anti-Bot Header
Cloudflare Bot Defense blocks requests with missing, generic, or scraper User-Agents. Every Dio request **MUST** include:
```http
User-Agent: VocaMobile/1.0.0 (Android; Mobile)
```

---

### Endpoint Reference

#### 1. `POST /api/transcript`
Fetches existing captions or orchestrates Gladia AI speech-to-text.

**Request Payload:**
```json
{
  "videoId": "clU8c2fpk2s",
  "lang": "ja",
  "preferAI": false,
  "jobId": "optional-gladia-job-id"
}
```

**Responses:**
- **Success (Native or cached transcript found):**
  ```json
  {
    "success": true,
    "source": "native",
    "language": "ja",
    "cues": [
      { "start": 1.25, "end": 4.10, "text": "夢ならばどれほどよかったでしょう" }
    ]
  }
  ```
- **Language Mismatch (Requested language not available, but other tracks exist):**
  ```json
  {
    "languageMismatch": true,
    "available": {
      "native": ["en", "ko"],
      "ai": []
    }
  }
  ```
- **Processing (Gladia AI ASR running):**
  ```json
  {
    "status": "processing",
    "jobId": "018d-...",
    "retryAfter": 5
  }
  ```
  *Client Behavior*: Poll `POST /api/transcript` every 5 seconds with `{ videoId, lang, jobId }` until `success: true`.

---

#### 2. `POST /api/tokenize-batch/:lang`
Tokenizes subtitle cues into morphological units with readings, base forms, and POS tags.

**Path Parameter:** `:lang` $\in$ `[ja, zh, ko, en]`  
**Request Payload:**
```json
{
  "videoId": "clU8c2fpk2s",
  "texts": [
    "夢ならばどれほどよかったでしょう",
    "未だにあなたのことを夢にみる"
  ]
}
```

**Response Format:**
```json
{
  "success": true,
  "language": "ja",
  "tokenizedCues": [
    [
      {
        "surface": "夢",
        "reading": "ゆめ",
        "romanization": "yume",
        "baseForm": "夢",
        "partOfSpeech": "名詞",
        "isPunctuation": false
      },
      {
        "surface": "ならば",
        "reading": "ならば",
        "romanization": "naraba",
        "baseForm": "なら",
        "partOfSpeech": "助詞",
        "isPunctuation": false
      }
    ]
  ]
}
```

---

#### 3. `GET /api/dict`
Unified dictionary lookup across multi-language providers.

**Query Parameters:**
- `q`: Word or phrase to look up.
- `from`: Source language (`ja`, `zh`, `ko`, `en`).
- `to`: Target definition language (`vi`, `en`, `ja`, etc.). Defaults to `en`.

**Provider Output Structs:**
- **Jotoba (JA-EN)** returns object maps for examples:
  ```json
  {
    "source": "jotoba",
    "entries": [
      {
        "word": "食べる",
        "reading": "たべる",
        "senses": [{ "glosses": ["to eat"], "pos": ["v1"] }],
        "examples": [{ "sentence": "ご飯を食べる", "translation": "Eat rice" }]
      }
    ]
  }
  ```
- **Mazii (JA-VI)** returns string arrays for examples:
  ```json
  {
    "source": "mazii",
    "entries": [
      {
        "word": "食べる",
        "reading": "たべる",
        "senses": [{ "glosses": ["ăn, dùng bữa"] }],
        "examples": ["ご飯を食べる (Ăn cơm)"]
      }
    ]
  }
  ```
> **Client Rule**: `DictionaryEntry.fromJson` in `voca_models.dart` must dynamically check `if (e is Map)` vs `if (e is String)`.

---

#### 4. `GET /api/recommended-videos`
Returns recommended immersion videos filtered by target language and CEFR/JLPT tier.

**Query Parameters:**
- `lang`: `ja`, `zh`, `ko`, or `en`.
- `tier`: `beginner`, `elementary`, `intermediate`, `advanced` (or omit for all).
- `limit`: Number of items (e.g. `20`).

---

## 2. Supabase Integration (`https://edbkvzviqeulwzcnrrlb.supabase.co`)

### Key Tables & Schema

#### 1. `vocabulary` (SM-2 Spaced Repetition Cards)
```sql
CREATE TABLE public.vocabulary (
  id text PRIMARY KEY,                   -- Deterministic Cyrb53 Base36 ID
  user_id uuid REFERENCES auth.users,
  word text NOT NULL,
  reading text,
  definition text NOT NULL,
  source_lang text NOT NULL,
  target_lang text NOT NULL,
  context_sentence text,
  srs_repetitions integer DEFAULT 0,
  srs_interval integer DEFAULT 0,       -- Review interval in days
  srs_ease_factor numeric DEFAULT 2.50,
  srs_next_review_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

#### 2. Atomic Daily Streaks RPC
Do not update streak counters directly via write queries. Call the atomic PostgreSQL stored procedure:
```dart
await supabase.rpc('record_streak_activity', params: {
  'p_user_id': userId,
  'p_activity_date': DateTime.now().toIso8601String().substring(0, 10),
});
```
This procedure atomically handles consecutive calendar day calculations, streak increments, and freeze item deductions.
