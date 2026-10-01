# Voca Flutter Mobile App

High-performance mobile language immersion application for Japanese, Chinese, Korean, and English learners using authentic YouTube videos.

## Features
- **Interactive Dual Subtitles**: Synchronized bilingual subtitles with Furigana (Japanese) and Pinyin (Chinese) ruby annotations.
- **Client-Side Grammar Engine**: Fast pattern detection for JLPT N5–N1, HSK 1–6, Korean 1–6, and CEFR A1–C2.
- **Morphological Tokenization**: Edge-accelerated Kuromoji segmentation and Part-of-Speech tagging.
- **Multi-Source Dictionary**: Instant word definition popups with one-tap addition to vocabulary notebook.
- **SM-2 Spaced Repetition (SRS)**: Offline-first flashcard review deck.
- **Gladia AI Audio Transcription**: ASR speech-to-text with auto-resumption and Turnstile CAPTCHA.

## Getting Started

1. Ensure the Flutter SDK (>= 3.19) is installed.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Architecture
- **Edge API**: `https://voca.study` (Cloudflare Pages Functions + R2 + D1 + KV)
- **User Cloud Sync**: `https://edbkvzviqeulwzcnrrlb.supabase.co` (Supabase PostgreSQL + RLS)
- **State Management**: `signals_flutter`
