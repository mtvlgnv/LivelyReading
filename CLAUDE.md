# LivelyReading — Project Context

## What this is
**A native SwiftUI reading app (iOS 16+), Apple Books-like in aesthetic, with
"Lexio" built in.** You read a book in a clean reader and **tap any word** to get
its *contextual* meaning (not a generic dictionary entry) in a popup, and save
words to a word bank.

- Repo: **github.com/mtvlgnv/LivelyReading** (public). Local: `/Users/mtvlgnv/LivelyReading`.
- The Xcode target / bundle id is `LexioReader` / `site.lexio.reader` (the repo
  name differs — no full rebrand done yet).

## Backend (separate repo)
This app is a client of **Lexio**, a FastAPI backend live at **https://lexio.site**
(separate monorepo at `/Users/mtvlgnv/lexio`). Endpoints this app uses:
- `POST /define` — word + context + lang + mode → contextual definition.
  Modes: Fast (free), Balanced/Deep (Pro, 403 `pro_required` otherwise).
- `POST /auth/{login,apple}`, `GET /auth/me`, `GET /api/pro-status`,
  `GET/POST /wordbank*`.
- `GET /api/catalog` + `GET /api/catalog/{slug}` — the public-domain book catalog
  (multi-language Project Gutenberg classics) the Discover tab imports from.
Base URL is `LexioReader/Config.swift` → `apiBaseURL` (prod = https://lexio.site;
point at http://localhost:8000 for local backend dev).

## Build & run
No `.xcodeproj` is committed — it's generated from `project.yml` via XcodeGen:
```bash
brew install xcodegen        # once
xcodegen generate            # produces LexioReader.xcodeproj
open LexioReader.xcodeproj    # ⌘R on a simulator
```
`build/` and `*.xcodeproj/` are gitignored.

## Structure
```
LexioReader/
├─ LexioReaderApp.swift   @main; injects AppState + LibraryStore + WordBankStore
├─ Config.swift           apiBaseURL, flags
├─ Models/                Definition, WordBankEntry, ReadingItem, ReadingMode,
│                         Language, Account, CatalogBook
├─ Services/              LexioAPI (define/auth/wordbank/catalog), LibraryStore,
│                         WordBankStore, Disk, KeychainStore, Speech, Theme
├─ State/AppState.swift   session, Pro status, preferences
└─ Views/                 RootView (tabs), LibraryView, AddTextView, BrowseView
                          (Discover), ReaderView (tokenized tap-to-define),
                          DefinitionSheet, WordBankView, SettingsView, SignInView
```

## Key behaviors
- **Reader**: `ReaderView` tokenizes text into tappable words (FlowLayout). Tapping
  opens `DefinitionSheet`, which calls `POST /define` with the enclosing paragraph
  as context. Free users get Fast; Balanced/Deep show an upgrade prompt.
- **Discover tab** (`BrowseView`): lists catalog books (language-filter chips),
  detail screen has "Add to Library" → fetches full text via `/api/catalog/{slug}`,
  saves a `ReadingItem` via `LibraryStore.add`, and pushes straight into the reader.
- `ReadingItem` is plain `title` + `body` (no chapter/EPUB structure yet — long
  novels import as one text blob; chapter model is a deferred decision).

## Scope guardrails
- The ONLY reader interaction is tap-a-word → contextual-definition popup. There is
  **no "AI companion"** (no summaries/recaps/chat). Don't add reading features
  beyond define + word bank without asking.

## Follow-ups (not done yet)
1. Sign in with Apple — UI + client exist behind `Config.enableAppleSignIn = false`;
   needs the capability in Xcode + server accepting this bundle id as token audience.
2. Native upgrade flow (currently links to web Stripe Checkout).
3. EPUB / Share-extension import; chapter model for long books.
4. App icon & launch art (system defaults for now).
5. Optional full rebrand from "Lexio"/"LexioReader" to "LivelyReading".
