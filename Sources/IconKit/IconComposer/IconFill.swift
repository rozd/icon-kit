/// Fill style for an icon document, group, or layer.
///
/// Encoding is polymorphic:
/// - String cases: `"automatic"`, `"system-light"`, `"system-dark"`
/// - Object cases: `{"solid": "srgb:1.0,0.0,0.0,1.0"}`, `{"automatic-gradient": "srgb:..."}`
public enum IconFill: Hashable, Sendable {
    /// System automatic fill.
    case automatic
    /// System light appearance fill.
    case systemLight
    /// System dark appearance fill.
    case systemDark
    /// A solid color fill.
    case solid(IconColor)
    /// An automatic gradient derived from a base color.
    case automaticGradient(IconColor)
}

// MARK: - Codable

extension IconFill: Codable {

    private enum StringValue: String {
        case automatic
        case systemLight = "system-light"
        case systemDark = "system-dark"
    }

    private enum ObjectKey: String, CodingKey {
        case solid
        case automaticGradient = "automatic-gradient"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try string cases first
        if let string = try? container.decode(String.self) {
            guard let stringValue = StringValue(rawValue: string) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unknown fill value: '\(string)'"
                )
            }
            switch stringValue {
            case .automatic: self = .automatic
            case .systemLight: self = .systemLight
            case .systemDark: self = .systemDark
            }
            return
        }

        // Try object cases
        let keyed = try decoder.container(keyedBy: ObjectKey.self)
        if let color = try keyed.decodeIfPresent(IconColor.self, forKey: .solid) {
            self = .solid(color)
        } else if let color = try keyed.decodeIfPresent(IconColor.self, forKey: .automaticGradient) {
            self = .automaticGradient(color)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown fill object format"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .automatic:
            var container = encoder.singleValueContainer()
            try container.encode(StringValue.automatic.rawValue)
        case .systemLight:
            var container = encoder.singleValueContainer()
            try container.encode(StringValue.systemLight.rawValue)
        case .systemDark:
            var container = encoder.singleValueContainer()
            try container.encode(StringValue.systemDark.rawValue)
        case .solid(let color):
            var container = encoder.container(keyedBy: ObjectKey.self)
            try container.encode(color, forKey: .solid)
        case .automaticGradient(let color):
            var container = encoder.container(keyedBy: ObjectKey.self)
            try container.encode(color, forKey: .automaticGradient)
        }
    }
}
