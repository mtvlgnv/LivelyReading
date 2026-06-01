import SwiftUI

/// A request to define a word in a given context — drives the definition sheet.
struct LookupRequest: Identifiable {
    let id = UUID()
    let word: String
    let context: String
}

/// One tappable unit of text. `display` keeps punctuation ("world,"); `lookup`
/// is the cleaned word sent to the API ("world"). Pure punctuation has an empty
/// `lookup` and isn't tappable.
struct Token: Identifiable, Hashable {
    let id: Int
    let display: String
    let lookup: String
}

/// A paragraph: its raw text (used as lookup context) and its tokens.
struct ParagraphBlock: Identifiable {
    let id: Int
    let text: String
    let tokens: [Token]
}

struct ReaderView: View {
    let item: ReadingItem

    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var library: LibraryStore

    @State private var blocks: [ParagraphBlock] = []
    @State private var selectedTokenID: Int?
    @State private var lookup: LookupRequest?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(blocks) { block in
                    FlowLayout {
                        ForEach(block.tokens) { token in
                            tokenView(token, context: block.text)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .primaryAction) { modeMenu } }
        .sheet(item: $lookup, onDismiss: { selectedTokenID = nil }) { req in
            DefinitionSheet(request: req)
        }
        .onAppear {
            if blocks.isEmpty { blocks = ReaderView.tokenize(item.body) }
            library.markOpened(item)
        }
    }

    // MARK: Token view

    private func tokenView(_ token: Token, context: String) -> some View {
        Text(token.display)
            .font(.reader(19))
            .lineSpacing(5)
            .padding(.horizontal, 2)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(selectedTokenID == token.id ? Color.lexioAccentSoft : .clear)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                guard !token.lookup.isEmpty else { return }
                selectedTokenID = token.id
                lookup = LookupRequest(word: token.lookup, context: context)
            }
            .accessibilityAddTraits(token.lookup.isEmpty ? [] : .isButton)
    }

    // MARK: Mode menu

    private var modeMenu: some View {
        Menu {
            Picker("Reading mode", selection: $app.mode) {
                ForEach(ReadingMode.allCases) { mode in
                    Label {
                        Text(mode.title +
                             (mode.requiresPro && !app.isPro ? "  (Pro)" : ""))
                    } icon: {
                        Image(systemName: mode.requiresPro && !app.isPro ? "lock.fill" : "circle")
                    }
                    .tag(mode)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "slider.horizontal.3")
                Text(app.mode.title)
            }
            .font(.subheadline.weight(.medium))
        }
    }

    // MARK: Tokenizer

    private static let trimSet = CharacterSet(charactersIn:
        ".,;:!?\"'`’‘“”()[]{}<>—–-…*_~|/\\")

    static func tokenize(_ body: String) -> [ParagraphBlock] {
        var blocks: [ParagraphBlock] = []
        var gid = 0
        var pid = 0
        for para in body.components(separatedBy: "\n") {
            if para.trimmingCharacters(in: .whitespaces).isEmpty { continue }
            var tokens: [Token] = []
            for chunk in para.split(whereSeparator: { $0.isWhitespace }) {
                let display = String(chunk)
                let lookup = display.trimmingCharacters(in: trimSet)
                tokens.append(Token(id: gid, display: display, lookup: lookup))
                gid += 1
            }
            blocks.append(ParagraphBlock(id: pid, text: para, tokens: tokens))
            pid += 1
        }
        return blocks
    }
}
