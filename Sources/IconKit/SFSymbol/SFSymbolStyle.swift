import CoreGraphics

/// Configuration for rendering an SF Symbol as an icon asset.
public struct SFSymbolStyle: Sendable {

    /// The SF Symbol name (e.g. `"shippingbox.fill"`).
    public var symbolName: String

    /// Foreground color applied to the symbol.
    public var foreground: CGColor

    /// Symbol size as a fraction of the canvas (0.0–1.0, where 1.0 fills the canvas).
    public var size: Double

    /// Fractional horizontal offset from center (positive = right).
    public var offsetX: Double

    /// Fractional vertical offset from center (positive = up).
    public var offsetY: Double

    public init(
        symbolName: String,
        foreground: CGColor,
        size: Double = 0.6,
        offsetX: Double = 0.0,
        offsetY: Double = 0.0
    ) {
        self.symbolName = symbolName
        self.foreground = foreground
        self.size = size
        self.offsetX = offsetX
        self.offsetY = offsetY
    }
}
