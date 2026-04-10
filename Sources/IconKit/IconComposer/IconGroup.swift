/// A group of layers within an icon document.
///
/// Groups are rendered back-to-front within the document.
/// Visual properties like shadow, translucency, and blend mode
/// can be overridden per appearance/idiom via specialization arrays.
public struct IconGroup: Codable, Hashable, Sendable {

    /// UUID string identifier for this group.
    public var id: String

    /// Optional display name.
    public var name: String?

    /// Layers within this group, rendered back-to-front.
    public var layers: [IconLayer]

    /// Base visibility flag.
    public var hidden: Bool?

    /// Base shadow configuration.
    public var shadow: IconShadow?

    /// Base translucency settings (visionOS).
    public var translucency: IconTranslucency?

    /// Blur material strength.
    public var blurMaterial: Double?

    /// Base opacity (0.0–1.0).
    public var opacity: Double?

    /// Lighting mode for this group.
    public var lighting: IconLighting?

    /// Whether specular highlights are enabled.
    public var specular: Bool?

    /// Base blend mode.
    public var blendMode: IconBlendMode?

    // MARK: - Specializations

    public var hiddenSpecializations: [Specialization<Bool>]?
    public var shadowSpecializations: [Specialization<IconShadow>]?
    public var translucencySpecializations: [Specialization<IconTranslucency>]?
    public var opacitySpecializations: [Specialization<Double>]?
    public var specularSpecializations: [Specialization<Bool>]?
    public var blendModeSpecializations: [Specialization<IconBlendMode>]?

    public init(
        id: String = "",
        name: String? = nil,
        layers: [IconLayer] = [],
        hidden: Bool? = nil,
        shadow: IconShadow? = nil,
        translucency: IconTranslucency? = nil,
        blurMaterial: Double? = nil,
        opacity: Double? = nil,
        lighting: IconLighting? = nil,
        specular: Bool? = nil,
        blendMode: IconBlendMode? = nil,
        hiddenSpecializations: [Specialization<Bool>]? = nil,
        shadowSpecializations: [Specialization<IconShadow>]? = nil,
        translucencySpecializations: [Specialization<IconTranslucency>]? = nil,
        opacitySpecializations: [Specialization<Double>]? = nil,
        specularSpecializations: [Specialization<Bool>]? = nil,
        blendModeSpecializations: [Specialization<IconBlendMode>]? = nil
    ) {
        self.id = id
        self.name = name
        self.layers = layers
        self.hidden = hidden
        self.shadow = shadow
        self.translucency = translucency
        self.blurMaterial = blurMaterial
        self.opacity = opacity
        self.lighting = lighting
        self.specular = specular
        self.blendMode = blendMode
        self.hiddenSpecializations = hiddenSpecializations
        self.shadowSpecializations = shadowSpecializations
        self.translucencySpecializations = translucencySpecializations
        self.opacitySpecializations = opacitySpecializations
        self.specularSpecializations = specularSpecializations
        self.blendModeSpecializations = blendModeSpecializations
    }

    enum CodingKeys: String, CodingKey {
        case id, name, layers, hidden, shadow, translucency, opacity, lighting, specular
        case blurMaterial = "blur-material"
        case blendMode = "blend-mode"
        case hiddenSpecializations = "hidden-specializations"
        case shadowSpecializations = "shadow-specializations"
        case translucencySpecializations = "translucency-specializations"
        case opacitySpecializations = "opacity-specializations"
        case specularSpecializations = "specular-specializations"
        case blendModeSpecializations = "blend-mode-specializations"
    }
}
