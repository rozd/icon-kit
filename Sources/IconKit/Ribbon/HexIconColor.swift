import CoreGraphics
import Foundation

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
