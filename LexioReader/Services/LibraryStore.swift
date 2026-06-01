import Foundation
import Combine

/// The local collection of saved texts. Persisted to disk on every change.
@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var items: [ReadingItem] = []

    private let fileName = "library.json"

    init() {
        items = Disk.load(fileName, as: [ReadingItem].self) ?? LibraryStore.seed
    }

    @discardableResult
    func add(title: String, body: String) -> ReadingItem {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = ReadingItem(
            title: cleanTitle.isEmpty ? ReadingItem.derivedTitle(from: body) : cleanTitle,
            body: body
        )
        items.insert(item, at: 0)
        persist()
        return item
    }

    /// True when a title with this exact name is already saved — used by the
    /// catalog to avoid importing the same book twice.
    func contains(title: String) -> Bool {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return items.contains { $0.title == t }
    }

    func markOpened(_ item: ReadingItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].lastOpenedAt = Date()
        persist()
    }

    func delete(_ item: ReadingItem) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        Disk.save(items, to: fileName)
    }

    /// A single welcoming sample so the reader isn't empty on first launch.
    private static let seed: [ReadingItem] = [
        ReadingItem(
            title: "Welcome to Lexio",
            body: """
            Tap any word to see what it means — not in the abstract, but right \
            here, in this sentence, the way it's actually being used.

            Lexio reads the surrounding context and explains the word's \
            contextual meaning, its part of speech, pronunciation, and \
            etymology. Save the ones worth remembering to your word bank.

            Paste an article, a chapter, or a difficult paragraph from the \
            Library tab, then read it here. The deeper reading modes — \
            Balanced and Deep — unlock with Pro.
            """
        )
    ]
}
