import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical") }

            BrowseView()
                .tabItem { Label("Discover", systemImage: "sparkles.rectangle.stack") }

            WordBankView()
                .tabItem { Label("Word Bank", systemImage: "bookmark") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
