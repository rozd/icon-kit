/// An individual image layer within an icon group.
///
/// Layers are rendered back-to-front within their parent group.
/// Each property can be overridden per appearance/idiom via specialization arrays.
public struct IconLayer: Codable, Hashable, Sendable {

    /// Optional identifier for this layer.
    public var id: String?

    /// Optional display name.
    public var name: String?

    /// Base image asset filename (in the Assets/ directory).
    public var imageName: String?

    /// Base fill style.
    public var fill: IconFill?

    /// Base blend mode.
    public var blendMode: IconBlendMode?

    /// Base opacity (0.0–1.0).
    public var opacity: Double?

    /// Base visibility flag.
    public var hidden: Bool?

    /// Whether visionOS glass effect is applied.
    public var glass: Bool?

    /// Base position and scale transform.
    public var position: IconPosition?

    // MARK: - Specializations

    public var imageNameSpecializations: [Specialization<String>]?
    public var fillSpecializations: [Specialization<IconFill>]?
    public var blendModeSpecializations: [Specialization<IconBlendMode>]?
    public var opacitySpecializations: [Specialization<Double>]?
    public var hiddenSpecializations: [Specialization<Bool>]?
    public var glassSpecializations: [Specialization<Bool>]?
    public var positionSpecializations: [Specialization<IconPosition>]?

    public init(
        id: String? = nil,
        name: String? = nil,
        imageName: String? = nil,
        fill: IconFill? = nil,
        blendMode: IconBlendMode? = nil,
        opacity: Double? = nil,
        hidden: Bool? = nil,
        glass: Bool? = nil,
        position: IconPosition? = nil,
        imageNameSpecializations: [Specialization<String>]? = nil,
        fillSpecializations: [Specialization<IconFill>]? = nil,
        blendModeSpecializations: [Specialization<IconBlendMode>]? = nil,
        opacitySpecializations: [Specialization<Double>]? = nil,
        hiddenSpecializations: [Specialization<Bool>]? = nil,
        glassSpecializations: [Specialization<Bool>]? = nil,
        positionSpecializations: [Specialization<IconPosition>]? = nil
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.fill = fill
        self.blendMode = blendMode
        self.opacity = opacity
        self.hidden = hidden
        self.glass = glass
        self.position = position
        self.imageNameSpecializations = imageNameSpecializations
        self.fillSpecializations = fillSpecializations
        self.blendModeSpecializations = blendModeSpecializations
        self.opacitySpecializations = opacitySpecializations
        self.hiddenSpecializations = hiddenSpecializations
        self.glassSpecializations = glassSpecializations
        self.positionSpecializations = positionSpecializations
    }

    enum CodingKeys: String, CodingKey {
        case id, name, fill, opacity, hidden, glass, position
        case imageName = "image-name"
        case blendMode = "blend-mode"
        case imageNameSpecializations = "image-name-specializations"
        case fillSpecializations = "fill-specializations"
        case blendModeSpecializations = "blend-mode-specializations"
        case opacitySpecializations = "opacity-specializations"
        case hiddenSpecializations = "hidden-specializations"
        case glassSpecializations = "glass-specializations"
        case positionSpecializations = "position-specializations"
    }
}
