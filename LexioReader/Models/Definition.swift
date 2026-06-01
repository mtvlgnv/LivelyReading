import Foundation

/// The payload returned by `POST /define`. The server spreads these fields at
/// the top level alongside `_usage` / `_hourly` metadata, which we ignore.
/// Single words populate all fields; phrases populate only definition /
/// contextual / why / register.
struct Definition: Codable, Hashable {
    var pos: String?
    var ipa: String?
    var definition: String?
    var contextual: String?
    var why: String?
    var simpler: String?
    var etymology: String?
    var register: String?

    /// True when the result looks like a multi-word phrase lookup (no pos/ipa).
    var isPhrase: Bool { pos == nil && ipa == nil }
}
