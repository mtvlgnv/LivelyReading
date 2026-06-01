import Foundation
import Combine

/// The local word bank. Always works offline; when the user is Pro and signed
/// in, saves are mirrored to the server and `pull()` merges the cloud copy in.
@MainActor
final class WordBankStore: ObservableObject {
    @Published private(set) var entries: [WordBankEntry] = []

    private let fileName = "wordbank.json"

    init() {
        entries = Disk.load(fileName, as: [WordBankEntry].self) ?? []
    }

    func contains(_ word: String) -> Bool {
        let key = word.lowercased()
        return entries.contains { $0.id == key }
    }

    func add(_ entry: WordBankEntry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[idx] = entry
        } else {
            entries.insert(entry, at: 0)
        }
        persist()
    }

    func remove(_ word: String) {
        let key = word.lowercased()
        entries.removeAll { $0.id == key }
        persist()
    }

    func remove(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        persist()
    }

    /// Merge a server snapshot into the local store (server wins on conflicts).
    func merge(_ remote: [WordBankEntry]) {
        var byKey: [String: WordBankEntry] = [:]
        for e in entries { byKey[e.id] = e }
        for e in remote { byKey[e.id] = e }
        entries = byKey.values.sorted {
            ($0.savedAt ?? "") > ($1.savedAt ?? "")
        }
        persist()
    }

    private func persist() {
        Disk.save(entries, to: fileName)
    }
}
