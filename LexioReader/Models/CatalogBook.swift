import Foundation

/// A book in Lexio's built-in catalog (public-domain titles served by the
/// backend at `/api/catalog`). Listing rows carry metadata only; the full text
/// is fetched separately via `CatalogBookDetail` when the user imports.
struct CatalogBook: Codable, Identifiable, Hashable {
    let slug: String
    let title: String
    let author: String
    let language: String
    let year: String
    let wordCount: Int
    let source: String?

    var id: String { slug }

    enum CodingKeys: String, CodingKey {
        case slug, title, author, language, year, source
        case wordCount = "word_count"
    }

    /// A human-friendly length, e.g. "127k words".
    var lengthLabel: String {
        if wordCount >= 1000 {
            return "\(wordCount / 1000)k words"
        }
        return "\(wordCount) words"
    }
}

/// One language present in the catalog, with how many books it has.
struct CatalogLanguage: Codable, Identifiable, Hashable {
    let code: String
    let name: String
    let count: Int

    var id: String { code }
}

/// The `/api/catalog` response: available languages plus all books.
struct CatalogResponse: Codable {
    let languages: [CatalogLanguage]
    let books: [CatalogBook]
}

/// The `/api/catalog/{slug}` response — metadata plus the full text body.
/// Extra metadata keys in the JSON are ignored by Codable.
struct CatalogBookDetail: Codable {
    let slug: String
    let title: String
    let author: String
    let body: String
}
