import Foundation

/// The three lookup engines, mirroring the web app's "Pick how you read".
/// The server enforces the Pro gate — Balanced and Deep return HTTP 403 with
/// `code: "pro_required"` for free/anonymous users, regardless of what we send.
enum ReadingMode: String, CaseIterable, Identifiable, Codable {
    case fast
    case balanced
    case deep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fast:     return "Fast"
        case .balanced: return "Balanced"
        case .deep:     return "Deep"
        }
    }

    var provider: String {
        switch self {
        case .fast:     return "OpenAI"
        case .balanced: return "Google"
        case .deep:     return "Anthropic"
        }
    }

    var engine: String {
        switch self {
        case .fast:     return "GPT-4o mini"
        case .balanced: return "Gemini 2.5 Flash"
        case .deep:     return "Claude Sonnet"
        }
    }

    var blurb: String {
        switch self {
        case .fast:     return "Quick, free lookups for everyday reading."
        case .balanced: return "Wide language coverage and strong contextual reasoning."
        case .deep:     return "The most thorough literary and etymological analysis."
        }
    }

    /// Balanced and Deep require an active Pro plan or trial on the server.
    var requiresPro: Bool { self != .fast }
}
