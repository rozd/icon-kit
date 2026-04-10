/// Platform targeting configuration for an icon document.
public struct SupportedPlatforms: Hashable, Sendable {

    /// Whether circular icons (watchOS) are supported.
    public var circles: Bool?

    /// Square icon platform configuration.
    public var squares: Squares?

    public init(circles: Bool? = nil, squares: Squares? = nil) {
        self.circles = circles
        self.squares = squares
    }

    /// Square icon platform variants.
    ///
    /// Encoding is polymorphic:
    /// - `"shared"` encodes as a bare string
    /// - `.platforms(["iOS", "macOS"])` encodes as `{"platforms": ["iOS", "macOS"]}`
    public enum Squares: Hashable, Sendable {
        /// Shared square icon across all platforms.
        case shared
        /// Platform-specific square icons.
        case platforms([String])
    }
}

// MARK: - Codable

extension SupportedPlatforms: Codable {

    enum CodingKeys: String, CodingKey {
        case circles
        case squares
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        circles = try container.decodeIfPresent(Bool.self, forKey: .circles)
        squares = try container.decodeIfPresent(Squares.self, forKey: .squares)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(circles, forKey: .circles)
        try container.encodeIfPresent(squares, forKey: .squares)
    }
}

extension SupportedPlatforms.Squares: Codable {

    private enum PlatformsKey: String, CodingKey {
        case platforms
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            guard string == "shared" else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unknown squares value: '\(string)'"
                )
            }
            self = .shared
            return
        }

        let keyed = try decoder.container(keyedBy: PlatformsKey.self)
        let platforms = try keyed.decode([String].self, forKey: .platforms)
        self = .platforms(platforms)
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .shared:
            var container = encoder.singleValueContainer()
            try container.encode("shared")
        case .platforms(let platforms):
            var container = encoder.container(keyedBy: PlatformsKey.self)
            try container.encode(platforms, forKey: .platforms)
        }
    }
}
