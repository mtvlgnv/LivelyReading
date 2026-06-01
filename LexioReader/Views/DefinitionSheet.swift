import SwiftUI

struct DefinitionSheet: View {
    let request: LookupRequest

    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var wordBank: WordBankStore
    @Environment(\.dismiss) private var dismiss

    private enum Phase {
        case loading
        case loaded(Definition)
        case failed(APIError)
    }

    @State private var phase: Phase = .loading
    @State private var overrideMode: ReadingMode?
    @State private var didSave = false

    private var effectiveMode: ReadingMode { overrideMode ?? app.mode }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch phase {
                    case .loading:        loadingView
                    case .loaded(let d):  loaded(d)
                    case .failed(let e):  failure(e)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(request.word)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task(id: effectiveMode) { await load() }
    }

    // MARK: States

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Reading \(request.word) in context…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
    }

    @ViewBuilder
    private func loaded(_ d: Definition) -> some View {
        header(d)

        if let contextual = d.contextual, !contextual.isEmpty {
            card(title: "In this passage", body: contextual, accent: true)
        }
        if let definition = d.definition, !definition.isEmpty {
            field(title: "Definition", body: definition)
        }
        if let why = d.why, !why.isEmpty {
            field(title: "Why this word", body: why)
        }
        if let etymology = d.etymology, !etymology.isEmpty {
            field(title: "Etymology", body: etymology)
        }
        saveButton(for: d)
    }

    @ViewBuilder
    private func failure(_ error: APIError) -> some View {
        if error.isProRequired {
            VStack(alignment: .leading, spacing: 14) {
                Label("\(effectiveMode.title) mode is a Pro feature",
                      systemImage: "lock.fill")
                    .font(.headline)
                Text("Upgrade to unlock Balanced and Deep, or look this word up with Fast — it's free.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button {
                    overrideMode = .fast
                } label: {
                    Label("Use Fast instead", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Link(destination: Config.upgradeURL) {
                    Text("See Pro plans →")
                        .font(.subheadline.weight(.medium))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text(error.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Try again") { Task { await load() } }
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
        }
    }

    // MARK: Pieces

    private func header(_ d: Definition) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(request.word)
                    .font(.system(.title, design: .serif).weight(.semibold))
                Button {
                    Speech.shared.speak(request.word)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Pronounce")
                Spacer()
            }
            if let ipa = d.ipa, !ipa.isEmpty {
                Text(ipa)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                if let pos = d.pos, !pos.isEmpty { chip(pos) }
                if let register = d.register, !register.isEmpty { chip(register) }
                if let simpler = d.simpler, !simpler.isEmpty { chip("≈ \(simpler)") }
            }
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.lexioAccentSoft))
            .foregroundStyle(Color.lexioAccent)
    }

    private func field(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
            Text(body)
                .font(.body)
        }
    }

    private func card(title: String, body: String, accent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.lexioAccent)
            Text(body)
                .font(.body)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.lexioAccentSoft))
    }

    private func saveButton(for d: Definition) -> some View {
        let alreadySaved = didSave || wordBank.contains(request.word)
        return Button {
            save(d)
        } label: {
            Label(alreadySaved ? "Saved to Word Bank" : "Save to Word Bank",
                  systemImage: alreadySaved ? "checkmark" : "bookmark")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(alreadySaved ? .secondary : .lexioAccent)
        .disabled(alreadySaved)
        .padding(.top, 4)
    }

    // MARK: Actions

    private func load() async {
        phase = .loading
        do {
            let def = try await app.api.define(
                word: request.word,
                context: request.context,
                lang: app.language.code,
                model: effectiveMode
            )
            phase = .loaded(def)
        } catch let error as APIError {
            phase = .failed(error)
        } catch {
            phase = .failed(APIError(status: -1, code: nil,
                                     message: "Something went wrong. Please try again."))
        }
    }

    private func save(_ d: Definition) {
        let entry = WordBankEntry(word: request.word, context: request.context, definition: d)
        wordBank.add(entry)
        didSave = true
        // Mirror to the cloud for Pro users (best-effort; ignore the free-tier 402).
        if app.isPro && app.isSignedIn {
            Task { try? await app.api.syncWordbank([entry]) }
        }
    }
}
