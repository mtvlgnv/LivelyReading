# Lively Reading — iOS

A native SwiftUI reading app, Apple Books–like in aesthetic, with **Lexio** built
in. Read a book in a clean reader and **tap any word** to get its *contextual*
meaning (not a generic dictionary entry) in a popup, and save words to a word
bank. No web view — real native UI talking to the same API as the Lexio website
and Chrome extension.

> Status: v1 draft. The core loop (library → reader → tap-to-define → word bank)
> plus a **Discover** tab of public-domain classics is complete and wired to
> `https://lexio.site`. Sign in with Apple is stubbed behind a flag (see
> *Follow-ups*).

## Build & run

This repo intentionally does **not** commit an `.xcodeproj` (the pbxproj is
noisy and merge-hostile). Generate it from `project.yml` with
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen        # once
xcodegen generate            # produces LivelyReading.xcodeproj
open LivelyReading.xcodeproj
```

Then pick a simulator and ⌘R. To run on a physical device, set your Apple Team
ID under *Signing & Capabilities* (or `DEVELOPMENT_TEAM` in `project.yml`).

**No XcodeGen?** Create a new iOS App in Xcode (SwiftUI lifecycle, name
`LivelyReading`), delete its `ContentView.swift`/generated `Info.plist`, then
drag the `LivelyReading/` folder in. Set the deployment target to iOS 16.

### Pointing at a local backend

Edit `LivelyReading/Config.swift` → `apiBaseURL`. `Info.plist` already allows
local networking, so `http://localhost:8000` works in the simulator.

## Architecture

```
LivelyReading/
├─ LivelyReadingApp.swift     @main; injects AppState + stores
├─ Config.swift               base URL, flags, product name
├─ Models/                    Definition, WordBankEntry, ReadingItem,
│                             ReadingMode, Language, Account, CatalogBook
├─ Services/
│   ├─ LexioAPI.swift         async client: /define, /auth/*, /wordbank*,
│   │                         /api/pro-status, /api/catalog*
│   ├─ KeychainStore.swift    session token storage
│   ├─ Disk.swift             JSON-file persistence (Application Support)
│   ├─ LibraryStore.swift     saved texts
│   ├─ WordBankStore.swift    saved words (local + cloud merge)
│   ├─ Speech.swift           AVSpeechSynthesizer pronunciation
│   └─ Theme.swift            brand color + reader font
├─ State/AppState.swift       session, Pro status, preferences
└─ Views/
    ├─ RootView.swift         tab bar (Library · Discover · Word Bank · Settings)
    ├─ LibraryView / AddTextView
    ├─ BrowseView.swift       Discover: catalog of public-domain classics →
    │                         "Add to Library" imports the text and opens it
    ├─ ReaderView.swift       tokenizes text; FlowLayout of tappable words
    ├─ FlowLayout.swift       wrapping Layout (iOS 16)
    ├─ DefinitionSheet.swift  lookup result + Pro-gate handling + save
    ├─ WordBankView.swift     list + read-only detail + pull-to-refresh sync
    ├─ SettingsView.swift     account, plan, mode/language, about
    └─ SignInView.swift       email/password (+ Apple, flagged)
```

> Internal symbols keep the `Lexio` name on purpose — `LexioAPI` (the backend
> client) and `Color.lexioAccent` (the brand palette) refer to the underlying
> Lexio engine, which powers the definitions. Only the app's *identity* and
> user-facing text are "Lively Reading".

### How a lookup works
Tapping a word sends `{ word, context, lang, model }` to `POST /define`, where
`context` is the enclosing paragraph (capped under the server's 8000-char
limit). `model` is the selected reading mode. Free/anonymous users get **Fast**;
**Balanced**/**Deep** return `403 pro_required`, which the sheet turns into an
upgrade prompt with a one-tap "Use Fast instead".

### Discover (catalog)
The Discover tab lists multi-language public-domain classics served by the
backend's `GET /api/catalog`. Picking a book and tapping **Add to Library**
fetches its full text via `GET /api/catalog/{slug}`, saves a `ReadingItem`, and
pushes straight into the reader. The only reader interaction is still
tap-a-word → contextual definition; the catalog just fills the library with
readable books.

### Auth
Bearer-token, matching the backend. The token is stored in the Keychain and
attached as `Authorization: Bearer …`. Anonymous use is fully supported (Fast
mode, local word bank). Word-bank **sync** is Pro-gated server-side (402 for
free users) and handled best-effort.

## Follow-ups (intentionally out of v1)

1. **Sign in with Apple** — UI + client call exist behind
   `Config.enableAppleSignIn = false`. To enable: (a) add the *Sign in with
   Apple* capability to the target in Xcode, and (b) update the server's
   `/auth/apple` to accept this app's **bundle ID** (`com.livelyreading.app`)
   as a valid token audience. Until then, email/password + anonymous cover
   sign-in.
2. **Upgrade flow** — Settings links to `lexio.site/#lp-pro` (web Stripe
   Checkout). A native StoreKit IAP is a separate decision (Apple's 15–30% cut
   vs. web billing).
3. **EPUB / share-extension import; chapter model** — v1 takes pasted text and
   whole-book catalog imports as one blob. A Share Extension and EPUB parsing,
   plus a chapter model for long books, are the obvious next on-ramps.
4. **App icon & launch art** — using system defaults for now.
