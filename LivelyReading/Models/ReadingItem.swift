import Foundation

/// A piece of text saved to the local library. v1 stores plain text (pasted or
/// shared in). EPUB import is a planned follow-up.
struct ReadingItem: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var body: String
    var createdAt: Date
    var lastOpenedAt: Date?

    init(id: UUID = UUID(), title: String, body: String,
         createdAt: Date = Date(), lastOpenedAt: Date? = nil) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.body = body
        self.createdAt = createdAt
        self.lastOpenedAt = lastOpenedAt
    }

    /// A short snippet for the library list.
    var preview: String {
        let flat = body
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return flat.count > 140 ? String(flat.prefix(140)) + "…" : flat
    }

    var wordCount: Int {
        body.split(whereSeparator: { $0.isWhitespace }).count
    }

    /// A reasonable title when the user doesn't supply one: first line, trimmed.
    static func derivedTitle(from body: String) -> String {
        let firstLine = body
            .split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true)
            .first.map(String.init) ?? "Untitled"
        let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Untitled" }
        return trimmed.count > 60 ? String(trimmed.prefix(60)) + "…" : trimmed
    }
}
