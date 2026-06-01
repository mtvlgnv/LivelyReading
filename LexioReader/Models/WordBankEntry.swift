import Foundation

/// A saved word. Shape matches the server's WBEntry (extra fields are ignored
/// on sync), so the same struct round-trips through `/wordbank` and
/// `/wordbank/sync`.
struct WordBankEntry: Codable, Identifiable, Hashable {
    var word: String
    var pos: String?
    var ipa: String?
    var definition: String?
    var contextual: String?
    var why: String?
    var simpler: String?
    var etymology: String?
    var register: String?
    /// The sentence/passage the word was looked up in.
    var context: String?
    /// ISO-8601 timestamp string, set when saved.
    var savedAt: String?

    /// Word bank is keyed case-insensitively on the server.
    var id: String { word.lowercased() }

    /// Build an entry from a fresh lookup.
    init(word: String, context: String?, definition def: Definition) {
        self.word = word
        self.pos = def.pos
        self.ipa = def.ipa
        self.definition = def.definition
        self.contextual = def.contextual
        self.why = def.why
        self.simpler = def.simpler
        self.etymology = def.etymology
        self.register = def.register
        self.context = context
        self.savedAt = ISO8601DateFormatter().string(from: Date())
    }

    /// Recover the Definition view-model from a stored entry (for re-display
    /// without another network call).
    var asDefinition: Definition {
        Definition(pos: pos, ipa: ipa, definition: definition,
                   contextual: contextual, why: why, simpler: simpler,
                   etymology: etymology, register: register)
    }
}
