import Foundation

/// A color value parsed from the Icon Composer string format: `"colorspace:c1,c2,c3,c4"`.
///
/// Examples:
/// - `"srgb:1.0,0.0,0.0,1.0"` — red in sRGB
/// - `"display-p3:0.5,0.5,0.5,1.0"` — gray in Display P3
/// - `"gray:0.5,1.0"` — 50% gray
public struct IconColor: Hashable, Sendable {

    public enum ColorSpace: String, Codable, Hashable, Sendable {
        case sRGB = "srgb"
        case extendedSRGB = "extended-srgb"
        case displayP3 = "display-p3"
        case gray = "gray"
        case extendedGray = "extended-gray"
    }

    public var colorSpace: ColorSpace
    public var components: [Double]

    public init(colorSpace: ColorSpace, components: [Double]) {
        self.colorSpace = colorSpace
        self.components = components
    }

    // MARK: - Convenience accessors

    public var red: Double? {
        guard !colorSpace.isGrayscale else { return nil }
        return components.count >= 1 ? components[0] : nil
    }

    public var green: Double? {
        guard !colorSpace.isGrayscale else { return nil }
        return components.count >= 2 ? components[1] : nil
    }

    public var blue: Double? {
        guard !colorSpace.isGrayscale else { return nil }
        return components.count >= 3 ? components[2] : nil
    }

    public var luminance: Double? {
        guard colorSpace.isGrayscale else { return nil }
        return components.count >= 1 ? components[0] : nil
    }

    public var alpha: Double? {
        switch colorSpace {
        case .gray, .extendedGray:
            return components.count >= 2 ? components[1] : nil
        default:
            return components.count >= 4 ? components[3] : nil
        }
    }

    // MARK: - String representation

    public var stringRepresentation: String {
        let comps = components.map { formatComponent($0) }.joined(separator: ",")
        return "\(colorSpace.rawValue):\(comps)"
    }
}

// MARK: - Codable

extension IconColor: Codable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(parsing: string)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringRepresentation)
    }
}

// MARK: - Parsing

extension IconColor {

    public init(parsing string: String) throws {
        guard let colonIndex = string.firstIndex(of: ":") else {
            throw IconColorError.invalidFormat(string)
        }

        let spaceRaw = String(string[string.startIndex..<colonIndex])
        let componentsRaw = String(string[string.index(after: colonIndex)...])

        guard let colorSpace = ColorSpace(rawValue: spaceRaw) else {
            throw IconColorError.unknownColorSpace(spaceRaw)
        }

        let parts = componentsRaw.split(separator: ",")
        let components = try parts.map { part -> Double in
            guard let value = Double(part.trimmingCharacters(in: .whitespaces)) else {
                throw IconColorError.invalidComponent(String(part))
            }
            return value
        }

        let expectedCount = colorSpace.isGrayscale ? 2 : 4
        guard components.count == expectedCount else {
            throw IconColorError.wrongComponentCount(
                colorSpace: colorSpace,
                expected: expectedCount,
                actual: components.count
            )
        }

        self.colorSpace = colorSpace
        self.components = components
    }
}

// MARK: - Errors

public enum IconColorError: Error, LocalizedError {
    case invalidFormat(String)
    case unknownColorSpace(String)
    case invalidComponent(String)
    case wrongComponentCount(colorSpace: IconColor.ColorSpace, expected: Int, actual: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidFormat(let string):
            "Invalid color format: '\(string)'. Expected 'colorspace:components'."
        case .unknownColorSpace(let space):
            "Unknown color space: '\(space)'."
        case .invalidComponent(let component):
            "Invalid color component: '\(component)'."
        case .wrongComponentCount(let colorSpace, let expected, let actual):
            "Color space '\(colorSpace.rawValue)' expects \(expected) components, got \(actual)."
        }
    }
}

// MARK: - Helpers

extension IconColor.ColorSpace {
    var isGrayscale: Bool {
        switch self {
        case .gray, .extendedGray: true
        default: false
        }
    }
}

private func formatComponent(_ value: Double) -> String {
    String(format: "%.5f", value)
}
