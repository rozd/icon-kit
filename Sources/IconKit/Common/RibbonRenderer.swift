import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Renders a ribbon overlay as a standalone transparent PNG image.
public struct RibbonRenderer: Sendable {

    public var placement: RibbonPlacement
    public var style: RibbonStyle

    public init(placement: RibbonPlacement, style: RibbonStyle) {
        self.placement = placement
        self.style = style
    }

    /// Generate a transparent PNG overlay containing just the ribbon and text.
    ///
    /// The output image is fully transparent except for the ribbon band.
    /// It can be used as an overlay layer in any icon format.
    ///
    /// - Parameters:
    ///   - width: Canvas width in pixels.
    ///   - height: Canvas height in pixels.
    ///   - viewport: Optional sub-rectangle of the canvas representing the visible icon area
    ///               (e.g. the 72dp center area of a 108dp Android adaptive icon canvas).
    /// - Returns: PNG data for the ribbon overlay image.
    public func generateOverlay(
        width: Int,
        height: Int,
        viewport: CGRect? = nil
    ) throws -> Data {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            throw RibbonRendererError.cannotCreateContext
        }

        // Start with fully transparent canvas
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))

        let targetArea = viewport ?? CGRect(x: 0, y: 0, width: Double(width), height: Double(height))
        let ribbonHeight = style.size * targetArea.height
        let offsetPixels = style.offset * targetArea.height

        switch placement {
        case .top:
            drawHorizontalRibbon(
                in: context,
                rect: CGRect(
                    x: 0,
                    y: targetArea.maxY - ribbonHeight - offsetPixels,
                    width: Double(width),
                    height: ribbonHeight
                ),
                textCenterX: targetArea.midX
            )
        case .bottom:
            drawHorizontalRibbon(
                in: context,
                rect: CGRect(
                    x: 0,
                    y: targetArea.minY + offsetPixels,
                    width: Double(width),
                    height: ribbonHeight
                ),
                textCenterX: targetArea.midX
            )
        case .topLeft, .topRight:
            drawDiagonalRibbon(
                in: context,
                canvasWidth: Double(width),
                canvasHeight: Double(height),
                targetArea: targetArea,
                ribbonHeight: ribbonHeight,
                offsetPixels: offsetPixels
            )
        }

        guard let outputImage = context.makeImage() else {
            throw RibbonRendererError.cannotCreateImage
        }

        return try encodePNG(outputImage)
    }

    // MARK: - Horizontal ribbon

    private func drawHorizontalRibbon(
        in context: CGContext,
        rect: CGRect,
        textCenterX: Double
    ) {
        // Background
        context.setFillColor(style.background)
        context.fill(rect)

        // Text
        let fontSize = rect.height * style.fontScale
        let line = makeLine(fontSize: fontSize)
        let textBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)

        let availableWidth = rect.width * 0.8
        let finalLine: CTLine
        let finalBounds: CGRect
        if textBounds.width > availableWidth {
            let scale = availableWidth / textBounds.width
            finalLine = makeLine(fontSize: fontSize * scale)
            finalBounds = CTLineGetBoundsWithOptions(finalLine, .useOpticalBounds)
        } else {
            finalLine = line
            finalBounds = textBounds
        }

        context.saveGState()
        context.setFillColor(style.foreground)
        let textX = textCenterX - finalBounds.width / 2 - finalBounds.origin.x
        let textY = rect.midY - finalBounds.height / 2 - finalBounds.origin.y
        context.textPosition = CGPoint(x: textX, y: textY)
        CTLineDraw(finalLine, context)
        context.restoreGState()
    }

    // MARK: - Diagonal ribbon

    /// Draw a diagonal corner ribbon using a transform-based approach:
    private func drawDiagonalRibbon(
        in context: CGContext,
        canvasWidth: Double,
        canvasHeight: Double,
        targetArea: CGRect,
        ribbonHeight: Double,
        offsetPixels: Double
    ) {
        // Corner and rotation angle from placement (CG coords: origin bottom-left)
        let cgCorner: CGPoint
        let angle: Double
        switch placement {
        case .topRight:
            cgCorner = CGPoint(x: targetArea.maxX, y: targetArea.maxY)
            angle = -Double.pi / 4  // 45° CW
        case .topLeft:
            cgCorner = CGPoint(x: targetArea.minX, y: targetArea.maxY)
            angle = Double.pi / 4   // 45° CCW
        default:
            return
        }

        // Ribbon long enough to always span beyond both canvas edges.
        let ribbonLength = (canvasWidth + canvasHeight) * 2.0

        // Perpendicular displacement in the rotated frame (-Y = into the icon):
        let ribbonCenterY = -(ribbonHeight / 2.0 + offsetPixels * sqrt(2.0))

        let ribbonRect = CGRect(
            x: -ribbonLength / 2.0,
            y: ribbonCenterY - ribbonHeight / 2.0,
            width: ribbonLength,
            height: ribbonHeight
        )

        // Text sizing
        let fontSize = ribbonHeight * style.fontScale
        let line = makeLine(fontSize: fontSize)
        let textBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)

        let visibleChord = 2.0 * abs(ribbonCenterY)
        let availableWidth = max(visibleChord * 0.8, targetArea.width * 0.4)

        let finalLine: CTLine
        let finalBounds: CGRect
        if textBounds.width > availableWidth {
            let scale = availableWidth / textBounds.width
            finalLine = makeLine(fontSize: fontSize * scale)
            finalBounds = CTLineGetBoundsWithOptions(finalLine, .useOpticalBounds)
        } else {
            finalLine = line
            finalBounds = textBounds
        }

        let textX = -finalBounds.width / 2.0 - finalBounds.origin.x
        let textY = ribbonCenterY - finalBounds.height / 2.0 - finalBounds.origin.y

        // Transform and draw.
        context.saveGState()
        context.translateBy(x: cgCorner.x, y: cgCorner.y)
        context.rotate(by: angle)

        // Background
        context.setFillColor(style.background)
        context.fill(ribbonRect)

        // Text
        context.setFillColor(style.foreground)
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: textX, y: textY)
        CTLineDraw(finalLine, context)

        context.restoreGState()
    }

    // MARK: - Text helpers

    private func makeLine(fontSize: CGFloat) -> CTLine {
        let font = makeFont(size: fontSize)
        let fontKey = NSAttributedString.Key(kCTFontAttributeName as String)
        let colorKey = NSAttributedString.Key(kCTForegroundColorAttributeName as String)
        let attributes: [NSAttributedString.Key: Any] = [
            fontKey: font,
            colorKey: style.foreground,
        ]
        let attrString = NSAttributedString(string: style.text, attributes: attributes)
        return CTLineCreateWithAttributedString(attrString)
    }

    private func makeFont(size: CGFloat) -> CTFont {
        let name = style.fontName ?? "HelveticaNeue-Bold"
        return CTFontCreateWithName(name as CFString, size, nil)
    }

    // MARK: - PNG encoding

    private func encodePNG(_ image: CGImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw RibbonRendererError.cannotEncodePNG
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw RibbonRendererError.cannotEncodePNG
        }
        return data as Data
    }
}

/// Errors from ribbon rendering.
public enum RibbonRendererError: Error, LocalizedError {
    case cannotCreateContext
    case cannotCreateImage
    case cannotEncodePNG

    public var errorDescription: String? {
        switch self {
        case .cannotCreateContext: "Cannot create graphics context."
        case .cannotCreateImage: "Cannot create output image."
        case .cannotEncodePNG: "Cannot encode PNG image data."
        }
    }
}
