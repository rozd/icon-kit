/// Where to position the ribbon on the icon.
public enum RibbonPlacement: String, CaseIterable, Sendable {
    /// Horizontal ribbon at the top edge.
    case top
    /// Horizontal ribbon at the bottom edge.
    case bottom
    /// Diagonal ribbon across the top-left corner.
    case topLeft
    /// Diagonal ribbon across the top-right corner.
    case topRight
}
