import Foundation

/// A typed error surfaced from the backend. `code` carries the server's
/// machine-readable reason (e.g. "pro_required", "hourly_limit") when present.
struct APIError: LocalizedError {
    let status: Int
    let code: String?
    let message: String

    var errorDescription: String? { message }

    var isProRequired: Bool { code == "pro_required" || status == 403 }
    var isRateLimited: Bool { code == "hourly_limit" || status == 429 }
    var isLimitReached: Bool { code == "limit_exceeded" || status == 402 }
    var isUnauthorized: Bool { status == 401 }
}

/// Network client for the Lexio backend. Set `token` after login to attach the
/// `Authorization: Bearer …` header to authenticated requests.
final class LexioAPI {
    var token: String?

    private let session: URLSession = .shared

    private lazy var decoder: JSONDecoder = JSONDecoder()
    private lazy var encoder: JSONEncoder = JSONEncoder()

    // MARK: Endpoints

    func define(word: String, context: String, lang: String, model: ReadingMode) async throws -> Definition {
        struct Body: Encodable { let word, context, lang, model: String }
        let trimmed = String(context.prefix(Config.maxContextChars))
        return try await request(
            "define", method: "POST",
            body: Body(word: word, context: trimmed, lang: lang, model: model.rawValue),
            authorized: true
        )
    }

    // MARK: Catalog (public — no auth required)

    /// The full book catalog: available languages plus all titles (metadata
    /// only). Light enough to fetch in one call and filter by language locally.
    func catalog() async throws -> CatalogResponse {
        try await request("api/catalog", authorized: false)
    }

    /// One book's metadata plus its full public-domain text, for import.
    func catalogBook(slug: String) async throws -> CatalogBookDetail {
        let encoded = slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? slug
        return try await request("api/catalog/\(encoded)", authorized: false)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        struct Body: Encodable { let email, password: String }
        return try await request("auth/login", method: "POST",
                                 body: Body(email: email, password: password),
                                 authorized: false)
    }

    func appleSignIn(idToken: String, name: String?) async throws -> AuthResponse {
        struct Body: Encodable {
            let id_token: String
            let name: String?
        }
        return try await request("auth/apple", method: "POST",
                                 body: Body(id_token: idToken, name: name),
                                 authorized: false)
    }

    func me() async throws -> UserAccount {
        try await request("auth/me")
    }

    func proStatus() async throws -> ProStatus {
        try await request("api/pro-status")
    }

    func wordbank() async throws -> [WordBankEntry] {
        struct Wrapper: Decodable { let entries: [WordBankEntry] }
        let w: Wrapper = try await request("wordbank")
        return w.entries
    }

    /// Push local entries; returns the merged server word bank. Throws an
    /// `APIError` with `isLimitReached`/`isProRequired` when the user is on the
    /// free tier (sync is Pro-only).
    @discardableResult
    func syncWordbank(_ entries: [WordBankEntry]) async throws -> [WordBankEntry] {
        struct Body: Encodable { let entries: [WordBankEntry] }
        struct Wrapper: Decodable { let entries: [WordBankEntry] }
        let w: Wrapper = try await request("wordbank/sync", method: "POST",
                                           body: Body(entries: entries), authorized: true)
        return w.entries
    }

    func deleteWord(_ word: String) async throws {
        let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? word
        let _: EmptyResponse = try await request("wordbank/\(encoded)", method: "DELETE")
    }

    func logout() async {
        // Best-effort; ignore failures.
        do {
            let _: EmptyResponse = try await request("auth/logout", method: "POST")
        } catch {
            // No-op: the token is cleared locally regardless.
        }
    }

    // MARK: Core request

    private struct EmptyResponse: Decodable {}

    private func request<T: Decodable>(_ path: String,
                                       method: String = "GET",
                                       body: (any Encodable)? = nil,
                                       authorized: Bool = true) async throws -> T {
        var req = URLRequest(url: Config.apiBaseURL.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if authorized, let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try encoder.encode(body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError(status: -1, code: nil,
                           message: "Network error. Check your connection and try again.")
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError(status: -1, code: nil, message: "Unexpected server response.")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw Self.decodeError(data, status: http.statusCode)
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError(status: http.statusCode, code: nil,
                           message: "Couldn't read the server's response.")
        }
    }

    /// FastAPI puts errors under `detail`, which may be a string or an object
    /// like `{ "code": "...", "message": "..." }`.
    private static func decodeError(_ data: Data, status: Int) -> APIError {
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let detail = obj["detail"] {
            if let s = detail as? String {
                return APIError(status: status, code: nil, message: s)
            }
            if let d = detail as? [String: Any] {
                let code = d["code"] as? String
                let message = d["message"] as? String ?? defaultMessage(status)
                return APIError(status: status, code: code, message: message)
            }
        }
        return APIError(status: status, code: nil, message: defaultMessage(status))
    }

    private static func defaultMessage(_ status: Int) -> String {
        switch status {
        case 401: return "Please sign in and try again."
        case 402: return "You've reached your free limit. Upgrade to keep going."
        case 403: return "This feature requires a Pro plan."
        case 429: return "You're going a bit fast — wait a moment and retry."
        case 500...599: return "The server had a problem. Please try again shortly."
        default: return "Something went wrong. Please try again."
        }
    }
}
