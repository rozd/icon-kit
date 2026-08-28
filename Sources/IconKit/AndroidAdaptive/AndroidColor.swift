import CoreGraphics
import Foundation

/// Utilities for parsing Android color specifications and resolving color resources.
public enum AndroidColor {

    /// Standard Android framework named colors (`@android:color/*`).
    public static let standardColors: [String: CGColor] = {
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        return [
            "@android:color/transparent": CGColor(colorSpace: space, components: [0, 0, 0, 0])!,
            "@android:color/black": CGColor(colorSpace: space, components: [0, 0, 0, 1])!,
            "@android:color/white": CGColor(colorSpace: space, components: [1, 1, 1, 1])!,
            "@android:color/darker_gray": CGColor(colorSpace: space, components: [0.67, 0.67, 0.67, 1])!,
            "@android:color/holo_blue_light": CGColor(colorSpace: space, components: [0.2, 0.71, 0.9, 1])!,
            "@android:color/holo_blue_dark": CGColor(colorSpace: space, components: [0, 0.6, 0.8, 1])!,
            "@android:color/holo_green_light": CGColor(colorSpace: space, components: [0.6, 0.8, 0.2, 1])!,
            "@android:color/holo_green_dark": CGColor(colorSpace: space, components: [0.4, 0.6, 0.13, 1])!,
            "@android:color/holo_red_light": CGColor(colorSpace: space, components: [1, 0.27, 0.27, 1])!,
            "@android:color/holo_red_dark": CGColor(colorSpace: space, components: [0.8, 0.13, 0.13, 1])!,
            "@android:color/holo_orange_light": CGColor(colorSpace: space, components: [1, 0.73, 0.2, 1])!,
            "@android:color/holo_orange_dark": CGColor(colorSpace: space, components: [1, 0.53, 0, 1])!,
            "@android:color/holo_purple": CGColor(colorSpace: space, components: [0.67, 0.4, 0.8, 1])!,
        ]
    }()

    /// Parse an Android color string, which can be:
    /// - A hex color (`#RGB`, `#ARGB`, `#RRGGBB`, `#AARRGGBB`)
    /// - An `@android:color/*` reference
    /// - A `@color/*` reference (resolved via the optional resolver)
    public static func parse(
        _ string: String,
        resolver: ((String) -> CGColor?)? = nil
    ) -> CGColor? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("#") {
            return parseHex(trimmed)
        }

        if let standard = standardColors[trimmed] {
            return standard
        }

        if let resolver {
            return resolver(trimmed)
        }

        return nil
    }

    /// Parse an Android hex color string into a `CGColor`.
    ///
    /// Android hex color formats:
    /// - `#RGB` -> `(r, g, b, 1.0)`
    /// - `#ARGB` -> `(r, g, b, a)` where A is the first character
    /// - `#RRGGBB` -> `(r, g, b, 1.0)`
    /// - `#AARRGGBB` -> `(r, g, b, a)` where AA is the first two characters
    public static func parseHex(_ hex: String) -> CGColor? {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("#") {
            clean.removeFirst()
        }

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }

        let count = clean.count
        guard [3, 4, 6, 8].contains(count),
              let intVal = UInt64(clean, radix: 16) else {
            return nil
        }

        let r, g, b, a: CGFloat

        switch count {
        case 3: // RGB
            r = CGFloat((intVal >> 8) & 0xF) / 15.0
            g = CGFloat((intVal >> 4) & 0xF) / 15.0
            b = CGFloat(intVal & 0xF) / 15.0
            a = 1.0

        case 4: // ARGB
            a = CGFloat((intVal >> 12) & 0xF) / 15.0
            r = CGFloat((intVal >> 8) & 0xF) / 15.0
            g = CGFloat((intVal >> 4) & 0xF) / 15.0
            b = CGFloat(intVal & 0xF) / 15.0

        case 6: // RRGGBB
            r = CGFloat((intVal >> 16) & 0xFF) / 255.0
            g = CGFloat((intVal >> 8) & 0xFF) / 255.0
            b = CGFloat(intVal & 0xFF) / 255.0
            a = 1.0

        case 8: // AARRGGBB
            a = CGFloat((intVal >> 24) & 0xFF) / 255.0
            r = CGFloat((intVal >> 16) & 0xFF) / 255.0
            g = CGFloat((intVal >> 8) & 0xFF) / 255.0
            b = CGFloat(intVal & 0xFF) / 255.0

        default:
            return nil
        }

        return CGColor(colorSpace: colorSpace, components: [r, g, b, a])
    }

    /// Discover and parse color definitions from all `values*/` XML files in a `res/` directory.
    public static func loadColors(from resDir: URL) -> [String: CGColor] {
        var colors: [String: CGColor] = [:]
        let fm = FileManager.default

        guard let contents = try? fm.contentsOfDirectory(
            at: resDir, includingPropertiesForKeys: [.isDirectoryKey]
        ) else {
            return colors
        }

        for dir in contents {
            let name = dir.lastPathComponent
            guard name == "values" || name.hasPrefix("values-") else { continue }

            guard let xmlFiles = try? fm.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil
            ) else { continue }

            for file in xmlFiles where file.pathExtension == "xml" {
                if let parsed = try? parseValuesXML(file: file) {
                    for (colorName, colorHex) in parsed {
                        if let cgColor = parseHex(colorHex) {
                            colors["@color/\(colorName)"] = cgColor
                        }
                    }
                }
            }
        }

        return colors
    }

    private static func parseValuesXML(file: URL) throws -> [String: String] {
        let data = try Data(contentsOf: file)
        let parser = ValuesXMLParser()
        return try parser.parse(data: data)
    }
}

// MARK: - Values XML Parser

private final class ValuesXMLParser: NSObject, XMLParserDelegate {
    private var colors: [String: String] = [:]
    private var currentName: String?
    private var currentText: String = ""

    func parse(data: Data) throws -> [String: String] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.parse()
        return colors
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String] = [:]
    ) {
        if elementName == "color" {
            currentName = attributes["name"]
            currentText = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        if elementName == "color", let name = currentName {
            let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                colors[name] = trimmed
            }
            currentName = nil
            currentText = ""
        }
    }
}
