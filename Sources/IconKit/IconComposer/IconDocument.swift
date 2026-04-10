/// Root model for the `icon.json` descriptor inside an `.icon` bundle.
///
/// An `IconDocument` describes all groups, layers, fills, and platform
/// targeting for an icon composition.
public struct IconDocument: Codable, Hashable, Sendable {

    /// Color space used for untagged SVG colors (e.g. `"display-p3"`).
    public var colorSpaceForUntaggedSVGColors: String?

    /// Base fill for the document background.
    public var fill: IconFill?

    /// Appearance/idiom-specific fill overrides.
    public var fillSpecializations: [Specialization<IconFill>]?

    /// Groups of layers, rendered back-to-front.
    public var groups: [IconGroup]

    /// Platform targeting configuration.
    public var supportedPlatforms: SupportedPlatforms?

    public init(
        colorSpaceForUntaggedSVGColors: String? = nil,
        fill: IconFill? = nil,
        fillSpecializations: [Specialization<IconFill>]? = nil,
        groups: [IconGroup] = [],
        supportedPlatforms: SupportedPlatforms? = nil
    ) {
        self.colorSpaceForUntaggedSVGColors = colorSpaceForUntaggedSVGColors
        self.fill = fill
        self.fillSpecializations = fillSpecializations
        self.groups = groups
        self.supportedPlatforms = supportedPlatforms
    }

    enum CodingKeys: String, CodingKey {
        case groups, fill
        case colorSpaceForUntaggedSVGColors = "color-space-for-untagged-svg-colors"
        case fillSpecializations = "fill-specializations"
        case supportedPlatforms = "supported-platforms"
    }
}
