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
    /// It is intended to be added as a front-most layer in an `.icon` bundle.
    ///
    /// - Parameters:
    ///   - width: Canvas width in pixels (typically 1024).
    ///   - height: Canvas height in pixels (typically 1024).
    /// - Returns: PNG data for the ribbon overlay image.
    public func generateOverlay(width: Int, height: Int) throws -> Data {
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

        let ribbonHeight = style.size * Double(height)
        let offsetPixels = style.offset * Double(height)

        switch placement {
        case .top:
            drawHorizontalRibbon(
                in: context,
                rect: CGRect(
                    x: 0,
                    y: Double(height) - ribbonHeight - offsetPixels,
                    width: Double(width),
                    height: ribbonHeight
                )
            )
        case .bottom:
            drawHorizontalRibbon(
                in: context,
                rect: CGRect(
                    x: 0,
                    y: offsetPixels,
                    width: Double(width),
                    height: ribbonHeight
                )
            )
        case .topLeft:
            drawDiagonalRibbon(
                in: context,
                imageWidth: Double(width),
                imageHeight: Double(height),
                ribbonHeight: ribbonHeight,
                offsetPixels: offsetPixels,
                angle: -.pi / 4,
                pivotX: 0,
                pivotY: Double(height),
                textDirection: 1.0
            )
        case .topRight:
            drawDiagonalRibbon(
                in: context,
                imageWidth: Double(width),
                imageHeight: Double(height),
                ribbonHeight: ribbonHeight,
                offsetPixels: offsetPixels,
                angle: .pi / 4,
                pivotX: Double(width),
                pivotY: Double(height),
                textDirection: -1.0
            )
        }

        guard let outputImage = context.makeImage() else {
            throw RibbonRendererError.cannotCreateImage
        }

        return try encodePNG(outputImage)
    }

    // MARK: - Horizontal ribbon

    private func drawHorizontalRibbon(in context: CGContext, rect: CGRect) {
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
        let textX = rect.midX - finalBounds.width / 2 - finalBounds.origin.x
        let textY = rect.midY - finalBounds.height / 2 - finalBounds.origin.y
        context.textPosition = CGPoint(x: textX, y: textY)
        CTLineDraw(finalLine, context)
        context.restoreGState()
    }

    // MARK: - Diagonal ribbon

    private func drawDiagonalRibbon(
        in context: CGContext,
        imageWidth: Double,
        imageHeight: Double,
        ribbonHeight: Double,
        offsetPixels: Double,
        angle: Double,
        pivotX: Double,
        pivotY: Double,
        textDirection: Double
    ) {
        // The ribbon center sits at `size * height` distance from the corner
        // along the perpendicular to the ribbon. The ribbon spans from edge
        // to edge at that distance. For a square icon at distance d from the
        // corner, the ribbon length that crosses both edges is 2*d.
        let distance = ribbonHeight / 2 + offsetPixels
        let ribbonLength = 2.0 * (distance + ribbonHeight)

        context.saveGState()

        // Move origin to the corner, then rotate
        context.translateBy(x: pivotX, y: pivotY)
        context.rotate(by: angle)

        // In the rotated frame, the ribbon is a horizontal band.
        // Position its center at -distance along Y (into the icon interior).
        let ribbonRect = CGRect(
            x: -ribbonLength / 2,
            y: -distance - ribbonHeight / 2,
            width: ribbonLength,
            height: ribbonHeight
        )

        // Background
        context.setFillColor(style.background)
        context.fill(ribbonRect)

        // Text
        let fontSize = ribbonHeight * style.fontScale
        let line = makeLine(fontSize: fontSize)
        let textBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)

        // Available width for text is based on the visible ribbon segment,
        // which is approximately 2 * distance wide
        let availableWidth = 2.0 * distance * 0.7
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

        // Center text in the visible portion of the ribbon.
        // In the rotated frame, x=0 maps to the image corner (clipped by squircle),
        // so shift text toward the icon interior along the ribbon.
        let visibleCenterX = textDirection * (distance + ribbonHeight / 2)
        context.setFillColor(style.foreground)
        context.textMatrix = .identity
        let textX = visibleCenterX - finalBounds.width / 2 - finalBounds.origin.x
        let textY = ribbonRect.midY - finalBounds.height / 2 - finalBounds.origin.y
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
