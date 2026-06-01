import SwiftUI

/// A left-to-right wrapping layout (iOS 16 `Layout`). Used to lay out tappable
/// word tokens so they wrap like running text while each stays an independent,
/// tappable view.
struct FlowLayout: Layout {
    var hSpacing: CGFloat = 3
    var vSpacing: CGFloat = 7

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widest: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                widest = max(widest, x - hSpacing)
                x = 0
                y += lineHeight + vSpacing
                lineHeight = 0
            }
            x += size.width + hSpacing
            lineHeight = max(lineHeight, size.height)
        }
        widest = max(widest, x - hSpacing)

        let width = proposal.width ?? max(widest, 0)
        return CGSize(width: width, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let maxWidth = bounds.width
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += lineHeight + vSpacing
                lineHeight = 0
            }
            subview.place(
                at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            x += size.width + hSpacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
