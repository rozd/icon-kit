import CoreGraphics
import Foundation

/// Errors that can occur when parsing a hex color string.
public enum HexColorError: Error, LocalizedError {
    case invalidFormat(String)
    case invalidHexCharacters(String)

    public var errorDescription: String? {
        switch self {
        case .invalidFormat(let hex):
            "Invalid hex color format: '\(hex)'. Expected '#RRGGBB' or '#RRGGBBAA'."
        case .invalidHexCharacters(let hex):
            "Invalid hex characters in: '\(hex)'."
        }
    }
}

/// Parse a hex color string into an ``IconColor`` in the sRGB color space.
///
/// Accepts formats: `"#RRGGBB"`, `"RRGGBB"`, `"#RRGGBBAA"`, `"RRGGBBAA"`.
public func parseHexIconColor(_ hex: String) throws -> IconColor {
    let cgColor = try parseHexColor(hex)
    guard let components = cgColor.components, components.count >= 3 else {
        throw HexColorError.invalidFormat(hex)
    }
    return IconColor(colorSpace: .sRGB, components: components.map(Double.init))
}

/// Parse a hex color string into a CGColor in the sRGB color space.
///
/// Accepts formats: `"#RRGGBB"`, `"RRGGBB"`, `"#RRGGBBAA"`, `"RRGGBBAA"`.
public func parseHexColor(_ hex: String) throws -> CGColor {
    var h = hex
    if h.hasPrefix("#") {
        h = String(h.dropFirst())
    }

    guard h.count == 6 || h.count == 8 else {
        throw HexColorError.invalidFormat(hex)
    }

    guard let value = UInt64(h, radix: 16) else {
        throw HexColorError.invalidHexCharacters(hex)
    }

    let r, g, b, a: CGFloat
    if h.count == 8 {
        r = CGFloat((value >> 24) & 0xFF) / 255.0
        g = CGFloat((value >> 16) & 0xFF) / 255.0
        b = CGFloat((value >> 8) & 0xFF) / 255.0
        a = CGFloat(value & 0xFF) / 255.0
    } else {
        r = CGFloat((value >> 16) & 0xFF) / 255.0
        g = CGFloat((value >> 8) & 0xFF) / 255.0
        b = CGFloat(value & 0xFF) / 255.0
        a = 1.0
    }

    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
          let color = CGColor(colorSpace: colorSpace, components: [r, g, b, a]) else {
        throw HexColorError.invalidFormat(hex)
    }
    return color
}
