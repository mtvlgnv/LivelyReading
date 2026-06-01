import Foundation

/// Output language for the semantic fields of a definition. `auto` lets the
/// server match the input text's language. Codes map to the server's
/// LANG_NAMES table; unknown codes are treated as auto, so this list is safe
/// to extend.
struct Language: Identifiable, Hashable {
    let code: String
    let name: String

    var id: String { code }

    static let auto = Language(code: "auto", name: "Auto-detect")

    static let all: [Language] = [
        .auto,
        Language(code: "en", name: "English"),
        Language(code: "es", name: "Spanish"),
        Language(code: "fr", name: "French"),
        Language(code: "de", name: "German"),
        Language(code: "it", name: "Italian"),
        Language(code: "pt", name: "Portuguese"),
        Language(code: "ru", name: "Russian"),
        Language(code: "ja", name: "Japanese"),
        Language(code: "zh", name: "Chinese"),
        Language(code: "ko", name: "Korean"),
        Language(code: "ar", name: "Arabic"),
    ]
}
