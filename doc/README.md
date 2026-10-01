# Voca Flutter Documentation Portal

Welcome to the internal engineering and architecture documentation for **Voca Flutter** (`voca_flutter`), the cross-platform mobile application for language immersion with authentic YouTube videos.

---

## Documentation Index

| Document | Description |
|---|---|
| [**Architecture & System Map**](./architecture.md) | High-level system topology, dual-backend layout, state reactivity with `signals_flutter`, and data flow. |
| [**API & Supabase Integration**](./api-integration.md) | Detailed specifications for Cloudflare Edge APIs (`https://voca.study/api/*`), Gladia ASR polling, and Supabase BaaS PostgreSQL tables/RPCs. |
| [**Features Deep Dive**](./features.md) | Subtitle rendering (Ruby/Furigana/Pinyin), GrammarEngine rule matcher, SM-2 Spaced Repetition (SRS), and YouTube player integration. |
| [**Development & Troubleshooting Guide**](./development-guide.md) | Quickstart setup, testing workflows, simulator/emulator setup, and known platform gotchas. |
| [**Agent Rules & Invariants**](./agents.md) | Critical non-negotiable rules for AI coding assistants (Anti-bot headers, deterministic IDs, YouTube player rules). |

---

## Repository Quick Summary

- **App Name**: Voca (Mobile)
- **Target Platforms**: Android (API 26+), iOS (14.0+), macOS (Desktop)
- **Core Languages**: Japanese (JA), Chinese (ZH), Korean (KO), English (EN)
- **State Management**: `signals_flutter` (Signals reactivity matching Angular 19)
- **Edge API Base URL**: `https://voca.study`
- **Supabase BaaS URL**: `https://edbkvzviqeulwzcnrrlb.supabase.co`
- **Video Engine**: `youtube_player_flutter: ^10.0.1` (backed by `youtube_player_iframe: ^6.0.2` & `webview_flutter`)
