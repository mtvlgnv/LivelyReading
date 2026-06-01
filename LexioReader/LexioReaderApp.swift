import SwiftUI

@main
struct LexioReaderApp: App {
    @StateObject private var app = AppState()
    @StateObject private var library = LibraryStore()
    @StateObject private var wordBank = WordBankStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
                .environmentObject(library)
                .environmentObject(wordBank)
                .tint(.lexioAccent)
                .task { await app.bootstrap() }
        }
    }
}
