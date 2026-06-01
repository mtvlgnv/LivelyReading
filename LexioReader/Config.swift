import Foundation

/// Global configuration. Point `apiBaseURL` at a local server during
/// development (e.g. http://localhost:8000) — the Info.plist already allows
/// local networking for that case.
enum Config {
    /// Base URL of the Lexio backend.
    static let apiBaseURL = URL(string: "https://lexio.site")!

    /// User-facing product name.
    static let appName = "Lexio"

    /// Where free users are sent to upgrade. Stripe Checkout lives on the web;
    /// there is no in-app purchase yet, so we open the marketing section.
    static let upgradeURL = URL(string: "https://lexio.site/#lp-pro")!

    /// Sign in with Apple is OFF by default. Turning it on requires two things:
    ///   1. Add the "Sign in with Apple" capability to the app target in Xcode.
    ///   2. Add this app's bundle identifier to the server's accepted Apple
    ///      token audiences (the `/auth/apple` endpoint currently validates
    ///      against APPLE_SERVICES_ID only — a native token's `aud` is the
    ///      bundle ID, so it must be allowed too).
    /// Until both are done, the email/password + anonymous paths cover sign-in.
    static let enableAppleSignIn = false

    /// Max characters of surrounding context we send with a lookup. The server
    /// caps `context` at 8000; we stay just under it.
    static let maxContextChars = 7800
}
