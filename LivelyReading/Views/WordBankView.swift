import SwiftUI

struct WordBankView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var wordBank: WordBankStore

    var body: some View {
        NavigationStack {
            Group {
                if wordBank.entries.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Word Bank")
        }
    }

    private var list: some View {
        List {
            ForEach(wordBank.entries) { entry in
                NavigationLink {
                    SavedWordDetail(entry: entry)
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(entry.word)
                                .font(.system(.headline, design: .serif))
                            if let ipa = entry.ipa, !ipa.isEmpty {
                                Text(ipa)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if let contextual = entry.contextual ?? entry.definition,
                           !contextual.isEmpty {
                            Text(contextual)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .onDelete(perform: delete)
        }
        .listStyle(.insetGrouped)
        .refreshable { await pull() }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bookmark")
                .font(.system(size: 44))
                .foregroundStyle(Color.lexioAccent)
            Text("No saved words yet")
                .font(.title3.weight(.semibold))
            Text("When you look up a word while reading, tap “Save to Word Bank” to keep it here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func delete(at offsets: IndexSet) {
        let words = offsets.map { wordBank.entries[$0].word }
        wordBank.remove(at: offsets)
        if app.isSignedIn {
            for word in words {
                Task { try? await app.api.deleteWord(word) }
            }
        }
    }

    private func pull() async {
        guard app.isSignedIn else { return }
        if let remote = try? await app.api.wordbank() {
            wordBank.merge(remote)
        }
    }
}

/// Read-only detail of a saved word — uses the stored fields, no network call.
private struct SavedWordDetail: View {
    let entry: WordBankEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(entry.word)
                        .font(.system(.largeTitle, design: .serif).weight(.semibold))
                    Button {
                        Speech.shared.speak(entry.word)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                    }
                    .buttonStyle(.borderless)
                }
                if let ipa = entry.ipa, !ipa.isEmpty {
                    Text(ipa).font(.callout.monospaced()).foregroundStyle(.secondary)
                }
                field("In this passage", entry.contextual)
                field("Definition", entry.definition)
                field("Why this word", entry.why)
                field("Etymology", entry.etymology)
                field("Original context", entry.context)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(entry.word)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func field(_ title: String, _ body: String?) -> some View {
        if let body, !body.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                Text(body).font(.body)
            }
        }
    }
}
