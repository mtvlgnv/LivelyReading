# Lexio for iOS — first version

A native SwiftUI reading app. Paste a text, read it in a clean reader, tap any
word to get its **contextual** meaning from the existing Lexio backend, and save
words to a word bank. No web view — this is real native UI talking to the same
API as the website and the Chrome extension.

> Status: v1 draft. The core loop (library → reader → tap-to-define → word bank)
> is complete and wired to `https://lexio.site`. Sign in with Apple is stubbed
> behind a flag (see *Follow-ups*).

## Build & run

This repo intentionally does **not** commit an `.xcodeproj` (the pbxproj is
noisy and merge-hostile). Generate it from `project.yml` with
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen        # once
cd ios
xcodegen generate           # produces LexioReader.xcodeproj
open LexioReader.xcodeproj
```

Then pick a simulator and ⌘R. To run on a physical device, set your Apple Team
ID under *Signing & Capabilities* (or `DEVELOPMENT_TEAM` in `project.yml`).

**No XcodeGen?** Create a new iOS App in Xcode (SwiftUI lifecycle, name
`LexioReader`), delete its `ContentView.swift`/generated `Info.plist`, then drag
the `LexioReader/` folder in. Set the deployment target to iOS 16.

### Pointing at a local backend

Edit `LexioReader/Config.swift` → `apiBaseURL`. `Info.plist` already allows
local networking, so `http://localhost:8000` works in the simulator.

## Architecture

```
LexioReader/
├─ LexioReaderApp.swift      @main; injects AppState + stores
├─ Config.swift              base URL, flags
├─ Models/                   Definition, WordBankEntry, ReadingItem,
│                            ReadingMode, Language, Account (+ ProStatus)
├─ Services/
│   ├─ LexioAPI.swift        async client: /define, /auth/*, /wordbank*, /api/pro-status
│   ├─ KeychainStore.swift   session token storage
│   ├─ Disk.swift            JSON-file persistence (Application Support)
│   ├─ LibraryStore.swift    saved texts
│   ├─ WordBankStore.swift   saved words (local + cloud merge)
│   ├─ Speech.swift          AVSpeechSynthesizer pronunciation
│   └─ Theme.swift           brand color + reader font
├─ State/AppState.swift      session, Pro status, preferences
└─ Views/
    ├─ RootView.swift        tab bar
    ├─ LibraryView / AddTextView
    ├─ ReaderView.swift      tokenizes text; FlowLayout of tappable words
    ├─ FlowLayout.swift      wrapping Layout (iOS 16)
    ├─ DefinitionSheet.swift lookup result + Pro-gate handling + save
    ├─ WordBankView.swift    list + read-only detail + pull-to-refresh sync
    ├─ SettingsView.swift    account, plan, mode/language, about
    └─ SignInView.swift      email/password (+ Apple, flagged)
```

### How a lookup works
Tapping a word sends `{ word, context, lang, model }` to `POST /define`, where
`context` is the enclosing paragraph (capped under the server's 8000-char
limit). `model` is the selected reading mode. Free/anonymous users get **Fast**;
**Balanced**/**Deep** return `403 pro_required`, which the sheet turns into an
upgrade prompt with a one-tap "Use Fast instead".

### Auth
Bearer-token, matching the backend. The token is stored in the Keychain and
attached as `Authorization: Bearer …`. Anonymous use is fully supported (Fast
mode, local word bank). Word-bank **sync** is Pro-gated server-side (402 for
free users) and handled best-effort.

## Follow-ups (intentionally out of v1)

1. **Sign in with Apple** — UI + client call exist behind
   `Config.enableAppleSignIn = false`. To enable: (a) add the *Sign in with
   Apple* capability to the target in Xcode, and (b) update the server's
   `/auth/apple` to accept this app's **bundle ID** as a valid token audience
   (it currently validates only `APPLE_SERVICES_ID`; a native token's `aud` is
   the bundle ID). Until then, email/password + anonymous cover sign-in.
2. **Upgrade flow** — Settings links to `lexio.site/#lp-pro` (web Stripe
   Checkout). A native StoreKit IAP is a separate decision (Apple's 15–30% cut
   vs. web billing).
3. **EPUB / share-extension import** — v1 takes pasted text. A Share Extension
   ("Share to Lexio" from Safari/Books) and EPUB parsing are the obvious next
   reading on-ramps.
4. **Trending words / recap** — `/api/annual-recap` and the trending endpoint
   aren't surfaced yet.
5. **App icon & launch art** — using system defaults for now.
