# PaperCode — Project Status

## Overview
Mobile-first AI code editor built with Flutter. SSH terminal + file manager evolved into a full code editing environment with AI assistance.

## Phase 1 — Code Editor Foundation ✅
- **Source abstraction** — unified `CodeSource` interface for Local, SSH, and GitHub sources
- **Local file browser** — browse/edit files on device storage via `path_provider`
- **Code editor** — syntax highlighting with `flutter_highlight` (Atom One Dark/Light themes), line numbers
- **Multi-tab editing** — open multiple files, switch tabs, dirty-dot indicators
- **Source picker** — switch between Local / SSH / GitHub from the editor top bar
- **GitHub API** — browse public/private repos via REST API
- **SSH file ops** — existing SSH client wrapped into `CodeSource` interface
- **App routing** — Editor is the main tab; SSH is no longer required to use the app

## Phase 2 — AI Assistant Integration ✅
- **In-editor AI chat** — toggleable panel (tap "AI" in top bar) that opens below the editor
- **File-aware AI** — AI automatically sees the currently open file and its contents
- **Apply to File** — AI outputs code blocks with an "Apply to File" button that replaces editor content
- **Multi-provider AI** — DeepSeek, Google Gemini, Groq, OpenAI, Ollama, Custom (existing, extended)
- **Quick API key setup** — "Get [Provider] Key" opens signup URL, "Paste Key" dialog in Settings
- **Google Sign-In** — code in place (needs Firebase/Google Cloud console setup to work)

## Phase 3 — Build & Preview (next)
- Detect project type (Flutter, web, etc.)
- On-device build (or remote build via SSH)
- Preview: web preview, Flutter hot-reload over network

## Phase 4 — Push & Deploy (next)
- Git integration (commit, push, PR)
- Deploy targets (GitHub Pages, VPS, etc.)

## Tech Stack
- **Flutter** 3.11+ with Dart 3.x
- **State management**: Provider
- **SSH**: dartssh2
- **Terminal**: xterm.dart
- **AI**: OpenAI-compatible streaming API (multiple providers)
- **Storage**: flutter_secure_storage
- **Code highlighting**: flutter_highlight
- **Auth**: google_sign_in
- **File picking**: file_picker

## Known Issues
- Crashes on Infinix X6528 (Mali GPU / Impeller rendering) — likely needs Impeller disabled or GPU workaround
- Google Sign-In needs Firebase/Google Cloud console setup
- GitHub source is read-only (no write support yet)

## Build
```sh
flutter pub get
flutter run
```
