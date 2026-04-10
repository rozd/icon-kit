/// Lighting mode for an icon group.
///
/// Controls whether lighting effects are applied to all layers together
/// or to each layer individually.
public enum IconLighting: String, Codable, Hashable, Sendable {
    case combined
    case individual
}
