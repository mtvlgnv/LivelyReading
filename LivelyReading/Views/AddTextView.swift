import SwiftUI

struct AddTextView: View {
    @EnvironmentObject private var library: LibraryStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var body_ = ""
    @FocusState private var bodyFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Title (optional)") {
                    TextField("Untitled", text: $title)
                }
                Section("Text") {
                    TextEditor(text: $body_)
                        .frame(minHeight: 240)
                        .font(.reader(17))
                        .focused($bodyFocused)
                        .overlay(alignment: .topLeading) {
                            if body_.isEmpty {
                                Text("Paste a paragraph, article, or chapter…")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                }
            }
            .navigationTitle("New Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        library.add(title: title, body: body_)
                        dismiss()
                    }
                    .disabled(body_.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { bodyFocused = true }
        }
    }
}
