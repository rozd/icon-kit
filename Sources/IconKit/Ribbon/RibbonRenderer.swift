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
                canvasSize: Double(max(width, height)),
                ribbonHeight: ribbonHeight,
                offsetPixels: offsetPixels,
                cornerX: 0,
                cornerY: 0,
                imageWidth: Double(width),
                imageHeight: Double(height)
            )
        case .topRight:
            drawDiagonalRibbon(
                in: context,
                canvasSize: Double(max(width, height)),
                ribbonHeight: ribbonHeight,
                offsetPixels: offsetPixels,
                cornerX: Double(width),
                cornerY: 0,
                imageWidth: Double(width),
                imageHeight: Double(height)
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

    /// Draw a diagonal corner ribbon.
    ///
    /// The ribbon is positioned so its centerline sits at `ribbonHeight/2 + offset`
    /// distance from the corner, perpendicular to the corner diagonal.
    /// `cornerX/cornerY` are in **visual** coordinates (origin top-left),
    /// converted to CG internally.
    private func drawDiagonalRibbon(
        in context: CGContext,
        canvasSize: Double,
        ribbonHeight: Double,
        offsetPixels: Double,
        cornerX: Double,
        cornerY: Double,
        imageWidth: Double,
        imageHeight: Double
    ) {
        // The ribbon's inner edge sits at `ribbonHeight + offset` from the corner
        // along each axis. In the 45° rotated frame, that distance from corner
        // along the perpendicular is (ribbonHeight + offset) / sqrt(2).
        let edgeDistance = ribbonHeight + offsetPixels
        let distance = edgeDistance / sqrt(2.0) + ribbonHeight / 2.0

        // The ribbon length must span from one canvas edge to the other at this
        // depth. At distance d from corner (perpendicular), the chord length is 2*d*sqrt(2).
        let ribbonLength = 2.0 * edgeDistance + ribbonHeight

        // Convert visual corner (origin top-left) to CG corner (origin bottom-left)
        let cgCornerX = cornerX
        let cgCornerY = imageHeight - cornerY

        // Determine rotation angle based on which corner:
        // topLeft  (0, h): rotate +45° so ribbon goes from left edge to top edge
        // topRight (w, h): rotate -45° so ribbon goes from top edge to right edge
        let isRight = cornerX > imageWidth / 2
        let angle = isRight ? (-Double.pi / 4) : (Double.pi / 4)

        // In the rotated frame, "into the icon" is the -Y direction
        // (away from the corner toward the center)
        let ribbonCenterY = -distance

        context.saveGState()
        context.translateBy(x: cgCornerX, y: cgCornerY)
        context.rotate(by: angle)

        let ribbonRect = CGRect(
            x: -ribbonLength / 2,
            y: ribbonCenterY - ribbonHeight / 2,
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

        let availableWidth = ribbonLength * 0.5
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
        // The visible center is offset from the corner along the ribbon.
        // For topLeft: positive X = toward icon interior along ribbon
        // For topRight: negative X = toward icon interior along ribbon
        // In the rotated frame, x=0 is the corner (off-screen in the squircle).
        // Shift text toward the visible interior of the icon.
        let textCenterX = isRight
            ? -(edgeDistance / 2)
            : (edgeDistance / 2)

        context.setFillColor(style.foreground)
        context.textMatrix = .identity
        let textX = textCenterX - finalBounds.width / 2 - finalBounds.origin.x
        let textY = ribbonCenterY - finalBounds.height / 2 - finalBounds.origin.y
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
