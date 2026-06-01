import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var app: AppState
    @State private var showingSignIn = false

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                subscriptionSection
                readingSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingSignIn) {
                SignInView()
            }
        }
    }

    // MARK: Account

    @ViewBuilder
    private var accountSection: some View {
        Section("Account") {
            if let account = app.account {
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.displayName).font(.headline)
                    Text(account.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Button(role: .destructive) {
                    Task { await app.signOut() }
                } label: {
                    Text("Sign out")
                }
            } else {
                Button {
                    showingSignIn = true
                } label: {
                    Label("Sign in", systemImage: "person.crop.circle")
                }
                Text("You can read and look up words with Fast mode without an account. Sign in to use Balanced and Deep and to sync your word bank.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Subscription

    @ViewBuilder
    private var subscriptionSection: some View {
        Section("Subscription") {
            HStack {
                Text("Plan")
                Spacer()
                Text(app.pro?.label ?? "Free")
                    .foregroundStyle(app.isPro ? Color.lexioAccent : .secondary)
                    .fontWeight(.medium)
            }
            if !app.isPro {
                Link(destination: Config.upgradeURL) {
                    Label("Upgrade to Pro", systemImage: "sparkles")
                }
            }
        }
    }

    // MARK: Reading

    private var readingSection: some View {
        Section("Reading") {
            Picker("Default mode", selection: $app.mode) {
                ForEach(ReadingMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            Picker("Definitions in", selection: $app.language) {
                ForEach(Language.all) { lang in
                    Text(lang.name).tag(lang)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(app.mode.provider + " · " + app.mode.engine)
                    .font(.footnote.weight(.medium))
                Text(app.mode.blurb)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(Self.versionString).foregroundStyle(.secondary)
            }
            Link(destination: URL(string: "https://lexio.site")!) {
                Label("lexio.site", systemImage: "safari")
            }
        }
    }

    private static var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
