import Foundation
import Combine

/// App-wide session + preferences. Owns the API client and brokers auth and
/// Pro status. Injected into the view tree as an `@EnvironmentObject`.
@MainActor
final class AppState: ObservableObject {
    // Session
    @Published private(set) var account: UserAccount?
    @Published private(set) var pro: ProStatus?
    @Published private(set) var isBootstrapping = true

    // Preferences (persisted in UserDefaults)
    @Published var mode: ReadingMode {
        didSet { defaults.set(mode.rawValue, forKey: Keys.mode) }
    }
    @Published var language: Language {
        didSet { defaults.set(language.code, forKey: Keys.language) }
    }

    let api = LexioAPI()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let mode = "pref.mode"
        static let language = "pref.language"
    }

    var isSignedIn: Bool { account != nil }
    var isPro: Bool { pro?.isPro == true }

    /// Whether a given mode can be used right now (free users get Fast only).
    func canUse(_ mode: ReadingMode) -> Bool {
        !mode.requiresPro || isPro
    }

    init() {
        let storedMode = defaults.string(forKey: Keys.mode).flatMap { ReadingMode(rawValue: $0) } ?? .fast
        mode = storedMode
        let storedLang = defaults.string(forKey: Keys.language)
        language = Language.all.first { $0.code == storedLang } ?? .auto
    }

    /// Restore a saved session (if any) and load status. Call once at launch.
    func bootstrap() async {
        defer { isBootstrapping = false }
        guard let token = KeychainStore.load() else { return }
        api.token = token
        do {
            account = try await api.me()
            await refreshStatus()
        } catch let error as APIError where error.isUnauthorized {
            // Stale/expired token — clear it silently.
            signOutLocally()
        } catch {
            // Network hiccup at launch: keep the token, try again later.
        }
    }

    func refreshStatus() async {
        guard isSignedIn else { pro = nil; return }
        pro = try? await api.proStatus()
    }

    // MARK: Auth

    func signIn(email: String, password: String) async throws {
        let response = try await api.login(email: email, password: password)
        applySession(response)
        await refreshStatus()
    }

    func signInWithApple(idToken: String, name: String?) async throws {
        let response = try await api.appleSignIn(idToken: idToken, name: name)
        applySession(response)
        await refreshStatus()
    }

    func signOut() async {
        await api.logout()
        signOutLocally()
    }

    private func applySession(_ response: AuthResponse) {
        KeychainStore.save(response.token)
        api.token = response.token
        account = response.user
    }

    private func signOutLocally() {
        KeychainStore.clear()
        api.token = nil
        account = nil
        pro = nil
    }
}
