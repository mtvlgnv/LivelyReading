import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryStore
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if library.items.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add text")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddTextView()
            }
        }
    }

    private var list: some View {
        List {
            ForEach(library.items) { item in
                NavigationLink {
                    ReaderView(item: item)
                } label: {
                    row(item)
                }
            }
            .onDelete { library.delete(at: $0) }
        }
        .listStyle(.insetGrouped)
    }

    private func row(_ item: ReadingItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.headline)
                .lineLimit(1)
            Text(item.preview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Text("\(item.wordCount) words")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 44))
                .foregroundStyle(Color.lexioAccent)
            Text("Nothing to read yet")
                .font(.title3.weight(.semibold))
            Text("Paste an article, a chapter, or a tricky paragraph and tap any word to understand it in context.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                showingAdd = true
            } label: {
                Label("Add text", systemImage: "plus")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
