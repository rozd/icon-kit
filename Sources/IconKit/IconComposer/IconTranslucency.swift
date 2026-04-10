/// Translucency settings for an icon group, primarily used for visionOS glass effects.
public struct IconTranslucency: Codable, Hashable, Sendable {

    /// Whether translucency is enabled.
    public var enabled: Bool

    /// Translucency intensity from 0.0 (opaque) to 1.0 (fully translucent).
    public var value: Double

    public init(enabled: Bool, value: Double) {
        self.enabled = enabled
        self.value = value
    }

    public static let disabled = IconTranslucency(enabled: false, value: 0.0)
    public static let `default` = IconTranslucency(enabled: true, value: 0.5)
}
