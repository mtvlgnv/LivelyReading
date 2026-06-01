import SwiftUI

/// Lexio's brand palette, approximated in sRGB from the web app's warm accent.
extension Color {
    static let lexioAccent = Color(red: 0.886, green: 0.384, blue: 0.180)   // ~#E2622E
    static let lexioAccentSoft = Color(red: 0.886, green: 0.384, blue: 0.180).opacity(0.14)
}

/// The reading typeface. SwiftUI's `.serif` design gives a book-like feel
/// without bundling a custom font; swap in Lora here if/when it's added.
extension Font {
    static func reader(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }
}
