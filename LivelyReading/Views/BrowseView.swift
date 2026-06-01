import SwiftUI

/// The catalog of public-domain books users can import into their library.
/// Lists titles from the backend `/api/catalog`, filterable by language, and
/// imports a book's full text into the local library on tap.
struct BrowseView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var library: LibraryStore

    @State private var phase: Phase = .loading
    @State private var languages: [CatalogLanguage] = []
    @State private var books: [CatalogBook] = []
    @State private var selectedLang: String? = nil   // nil == all
    @State private var path = NavigationPath()

    private enum Phase: Equatable { case loading, loaded, failed(String) }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("Discover")
                .navigationDestination(for: CatalogBook.self) { book in
                    BookDetailView(book: book, path: $path)
                }
                .navigationDestination(for: ReadingItem.self) { item in
                    ReaderView(item: item)
                }
        }
        .task { await loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            ProgressView("Loading books…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            errorState(message)
        case .loaded:
            VStack(spacing: 0) {
                if languages.count > 1 { languageFilter }
                bookList
            }
        }
    }

    private var filteredBooks: [CatalogBook] {
        guard let lang = selectedLang else { return books }
        return books.filter { $0.language == lang }
    }

    // MARK: Language filter

    private var languageFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", code: nil)
                ForEach(languages) { lang in
                    chip(title: "\(lang.name) (\(lang.count))", code: lang.code)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func chip(title: String, code: String?) -> some View {
        let selected = selectedLang == code
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedLang = code }
        } label: {
            Text(title)
                .font(.subheadline.weight(selected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(selected ? Color.lexioAccent : Color.lexioAccentSoft)
                )
                .foregroundStyle(selected ? .white : Color.lexioAccent)
        }
        .buttonStyle(.plain)
    }

    // MARK: Book list

    private var bookList: some View {
        List(filteredBooks) { book in
            NavigationLink(value: book) {
                row(book)
            }
        }
        .listStyle(.plain)
    }

    private func row(_ book: CatalogBook) -> some View {
        HStack(spacing: 12) {
            coverPlaceholder(book)
            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.reader(17))
                    .lineLimit(2)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("\(languageName(book.language)) · \(book.lengthLabel)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
            if library.contains(title: book.title) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.lexioAccent)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }

    /// A simple typographic "cover" — we don't have artwork for PD scans.
    private func coverPlaceholder(_ book: CatalogBook) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color.lexioAccentSoft)
            .frame(width: 44, height: 62)
            .overlay(
                Text(book.title.prefix(1))
                    .font(.reader(24))
                    .foregroundStyle(Color.lexioAccent)
            )
    }

    private func languageName(_ code: String) -> String {
        languages.first { $0.code == code }?.name ?? code.uppercased()
    }

    // MARK: States

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 38))
                .foregroundStyle(.secondary)
            Text("Couldn't load books")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try again") {
                phase = .loading
                Task { await load() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Loading

    private func loadIfNeeded() async {
        if books.isEmpty { await load() }
    }

    private func load() async {
        do {
            let response = try await app.api.catalog()
            languages = response.languages
            books = response.books
            phase = .loaded
        } catch let error as APIError {
            phase = .failed(error.message)
        } catch {
            phase = .failed("Please check your connection and try again.")
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Detail + import screen for a single catalog book.
struct BookDetailView: View {
    let book: CatalogBook
    @Binding var path: NavigationPath

    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var library: LibraryStore

    @State private var importing = false
    @State private var errorMessage: String?

    private var alreadySaved: Bool { library.contains(title: book.title) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.lexioAccentSoft)
                    .frame(width: 120, height: 168)
                    .overlay(
                        Text(book.title.prefix(1))
                            .font(.reader(56))
                            .foregroundStyle(Color.lexioAccent)
                    )
                    .padding(.top, 8)

                VStack(spacing: 6) {
                    Text(book.title)
                        .font(.reader(24))
                        .multilineTextAlignment(.center)
                    Text(book.author)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("\(book.year) · \(book.lengthLabel)")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 24)

                importButton

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Text("Public-domain text from Project Gutenberg.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 32)
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var importButton: some View {
        if alreadySaved {
            Label("In your Library", systemImage: "checkmark.circle.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.lexioAccent)
        } else {
            Button {
                Task { await importBook() }
            } label: {
                HStack(spacing: 8) {
                    if importing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "arrow.down.circle")
                    }
                    Text(importing ? "Adding…" : "Add to Library")
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: 280)
            }
            .buttonStyle(.borderedProminent)
            .disabled(importing)
        }
    }

    private func importBook() async {
        importing = true
        errorMessage = nil
        defer { importing = false }
        do {
            let detail = try await app.api.catalogBook(slug: book.slug)
            let item = library.add(title: detail.title, body: detail.body)
            // Drop straight into the reader for the freshly-added book.
            path.append(item)
        } catch let error as APIError {
            errorMessage = error.message
        } catch {
            errorMessage = "Couldn't download this book. Please try again."
        }
    }
}
