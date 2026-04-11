import CoreGraphics

/// Visual configuration for an icon ribbon overlay.
public struct RibbonStyle: Sendable {

    /// Text to render on the ribbon.
    public var text: String

    /// Ribbon size as a factor of icon height (0.0–1.0). Default: 0.24.
    public var size: Double

    /// Offset from the closest edge as a factor of icon height (0.0–1.0). Default: 0.0.
    public var offset: Double

    /// Ribbon background color.
    public var background: CGColor

    /// Text color.
    public var foreground: CGColor

    /// Font family name. Nil uses the default (Helvetica Neue Bold).
    public var fontName: String?

    /// Font scale as a factor of ribbon height (0.0–1.0). Default: 0.6.
    public var fontScale: Double

    public init(
        text: String,
        size: Double = 0.24,
        offset: Double = 0.0,
        background: CGColor = CGColor(srgbRed: 0xB9 / 255.0, green: 0x26 / 255.0, blue: 0x36 / 255.0, alpha: 1),
        foreground: CGColor = CGColor(srgbRed: 0xFE / 255.0, green: 0xFA / 255.0, blue: 0xFA / 255.0, alpha: 1),
        fontName: String? = nil,
        fontScale: Double = 0.6
    ) {
        self.text = text
        self.size = size
        self.offset = offset
        self.background = background
        self.foreground = foreground
        self.fontName = fontName
        self.fontScale = fontScale
    }
}
