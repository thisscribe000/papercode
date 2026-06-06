# PaperCode — Project Status

## Overview
Mobile-first AI code editor built with Flutter. SSH terminal + file manager evolved into a full code editing environment with AI assistance.

## Phase 1 — Code Editor Foundation ✅
- **Source abstraction** — unified `CodeSource` interface for Local, SSH, and GitHub sources
- **Local file browser** — browse/edit files on device storage via `path_provider`
- **Code editor** — syntax highlighting with `flutter_highlight` (Atom One Dark/Light themes), line numbers
- **Multi-tab editing** — open multiple files, switch tabs, dirty-dot indicators
- **Source picker** — switch between Local / SSH / GitHub from the editor top bar
- **GitHub API** — browse public/private repos via REST API, **write support via Content API** ✅
- **SSH file ops** — existing SSH client wrapped into `CodeSource` interface
- **App routing** — Editor is the main tab; SSH is no longer required to use the app

## Phase 2 — AI Assistant Integration ✅
- **In-editor AI chat** — toggleable panel (tap "AI" in top bar) that opens below the editor
- **File-aware AI** — AI automatically sees the currently open file and its contents
- **Apply to File** — AI outputs code blocks with an "Apply to File" button that replaces editor content
- **Multi-provider AI** — DeepSeek, Google Gemini, Groq, OpenAI, Ollama, Custom (existing, extended)
- **Quick API key setup** — "Get [Provider] Key" opens signup URL, "Paste Key" dialog in Settings
- **Google Sign-In** — configured with OAuth 2.0 client IDs for Android/iOS, session persists across app restarts

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

## Known Issues — Resolved ✅
- ~~Crashes on Infinix X6528 (Mali GPU / Impeller rendering)~~ — Impeller disabled in AndroidManifest.xml
- ~~GitHub source is read-only~~ — Content API write support implemented (writeFile, deleteFile)
- ~~Google Sign-In not persisting across app restarts~~ — signInSilently() auto-restores session
- ~~Keyboard dismisses after every keystroke~~ — stable widget key keeps editor focus alive

## Google Sign-In Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com) → APIs & Services → Credentials
2. Create an OAuth 2.0 Client ID for **Android**:
   - Package name: `com.example.papercode`
   - SHA-1: `8C:56:FE:4A:4D:CF:9F:B4:6C:4B:F2:68:7E:D3:54:6B:34:A8:CC:68`
3. Create an OAuth 2.0 Client ID for **iOS** with bundle ID `com.example.papercode`
4. Enable **Google Sign-In** in the OAuth consent screen configuration

## Build
```sh
flutter pub get
flutter run
```
