import Foundation

/// Parsed model of an Android adaptive icon XML descriptor.
///
/// Represents the `<adaptive-icon>` element with its layer references:
/// ```xml
/// <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
///     <background android:drawable="@drawable/ic_launcher_background"/>
///     <foreground android:drawable="@drawable/ic_launcher_foreground"/>
///     <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
/// </adaptive-icon>
/// ```
public struct AdaptiveIcon: Hashable, Sendable {

    /// Drawable reference for the background layer (e.g. `"@drawable/ic_launcher_background"`).
    public var background: String?

    /// Drawable reference for the foreground layer (e.g. `"@drawable/ic_launcher_foreground"`).
    public var foreground: String?

    /// Drawable reference for the monochrome layer (e.g. `"@drawable/ic_launcher_monochrome"`).
    public var monochrome: String?

    public init(background: String? = nil, foreground: String? = nil, monochrome: String? = nil) {
        self.background = background
        self.foreground = foreground
        self.monochrome = monochrome
    }

    /// Parse an adaptive icon descriptor from XML data.
    public init(xmlData: Data) throws {
        let parser = AdaptiveIconXMLParser()
        try parser.parse(data: xmlData)
        self.background = parser.background
        self.foreground = parser.foreground
        self.monochrome = parser.monochrome
    }

    /// Serialize this descriptor back to XML data.
    public func xmlData() -> Data {
        var xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
        xml += "<adaptive-icon xmlns:android=\"http://schemas.android.com/apk/res/android\">\n"
        if let background {
            xml += "    <background android:drawable=\"\(background)\"/>\n"
        }
        if let foreground {
            xml += "    <foreground android:drawable=\"\(foreground)\"/>\n"
        }
        if let monochrome {
            xml += "    <monochrome android:drawable=\"\(monochrome)\"/>\n"
        }
        xml += "</adaptive-icon>\n"
        return Data(xml.utf8)
    }
}

// MARK: - Drawable reference parsing

extension AdaptiveIcon {

    /// Parse a drawable reference like `"@drawable/name"` or `"@mipmap/name"`
    /// into its type and name components.
    ///
    /// - Returns: A tuple of `(type, name)`, e.g. `("drawable", "ic_launcher_foreground")`.
    public static func parseDrawableReference(_ ref: String) -> (type: String, name: String)? {
        guard ref.hasPrefix("@") else { return nil }
        let stripped = String(ref.dropFirst()) // remove "@"
        let parts = stripped.split(separator: "/", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        return (type: String(parts[0]), name: String(parts[1]))
    }
}

// MARK: - XML Parser

private final class AdaptiveIconXMLParser: NSObject, XMLParserDelegate {
    var background: String?
    var foreground: String?
    var monochrome: String?
    private var parseError: Error?

    func parse(data: Data) throws {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        guard parser.parse() else {
            let detail = parseError?.localizedDescription
                ?? parser.parserError?.localizedDescription
                ?? "unknown error"
            throw AdaptiveIconError.invalidXML(detail)
        }
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String]
    ) {
        let drawable = attributes["android:drawable"]
        switch elementName {
        case "background": background = drawable
        case "foreground": foreground = drawable
        case "monochrome": monochrome = drawable
        default: break
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
}
