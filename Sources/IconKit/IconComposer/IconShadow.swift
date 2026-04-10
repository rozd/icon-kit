/// Shadow configuration for an icon group.
public struct IconShadow: Codable, Hashable, Sendable {

    /// The kind of shadow to apply.
    public enum Kind: String, Codable, Hashable, Sendable {
        /// A neutral gray shadow.
        case neutral
        /// A shadow colored to match the layer content.
        case layerColor
    }

    public var kind: Kind
    public var opacity: Double

    public init(kind: Kind, opacity: Double) {
        self.kind = kind
        self.opacity = opacity
    }

    public static let neutral = IconShadow(kind: .neutral, opacity: 1.0)
    public static let layerColor = IconShadow(kind: .layerColor, opacity: 1.0)
}
