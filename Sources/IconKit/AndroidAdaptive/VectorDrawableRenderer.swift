import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Renders Android `VectorDrawable` trees to raster images (`CGImage` or PNG `Data`).
public struct VectorDrawableRenderer: Sendable {

    public var vector: VectorDrawable
    public var colorResolver: (@Sendable (String) -> CGColor?)?

    public init(
        vector: VectorDrawable,
        colorResolver: (@Sendable (String) -> CGColor?)? = nil
    ) {
        self.vector = vector
        self.colorResolver = colorResolver
    }

    /// Render the vector drawable to a `CGImage` of the specified pixel dimensions.
    public func renderImage(width: Int, height: Int) throws -> CGImage {
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
            throw AdaptiveIconError.cannotResolveDrawable("Cannot create graphics context for rendering vector")
        }

        // Start with a transparent canvas
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))

        context.saveGState()

        // Flip coordinate system: CoreGraphics is bottom-left, VectorDrawable is top-left
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)

        // Scale from viewport coordinates to canvas pixel size
        let vpWidth = vector.viewportWidth > 0 ? vector.viewportWidth : vector.width
        let vpHeight = vector.viewportHeight > 0 ? vector.viewportHeight : vector.height
        let scaleX = CGFloat(width) / CGFloat(vpWidth)
        let scaleY = CGFloat(height) / CGFloat(vpHeight)
        context.scaleBy(x: scaleX, y: scaleY)

        // Apply overall vector alpha
        if vector.alpha < 1.0 {
            context.setAlpha(CGFloat(vector.alpha))
        }

        // Render root elements
        for element in vector.elements {
            renderElement(element, in: context)
        }

        context.restoreGState()

        guard let image = context.makeImage() else {
            throw AdaptiveIconError.cannotResolveDrawable("Cannot create image from vector context")
        }

        return image
    }

    /// Render the vector drawable to PNG image data.
    public func renderPNG(width: Int, height: Int) throws -> Data {
        let image = try renderImage(width: width, height: height)
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

    // MARK: - Element rendering

    private func renderElement(_ element: VectorElement, in context: CGContext) {
        switch element {
        case .group(let group):
            renderGroup(group, in: context)
        case .path(let path):
            renderPath(path, in: context)
        case .clipPath(let clip):
            renderClipPath(clip, in: context)
        }
    }

    private func renderGroup(_ group: VectorGroup, in context: CGContext) {
        context.saveGState()

        // Apply group transform:
        // translate(pivotX + translateX, pivotY + translateY)
        // rotate(rotation)
        // scale(scaleX, scaleY)
        // translate(-pivotX, -pivotY)
        let transX = group.translateX + group.pivotX
        let transY = group.translateY + group.pivotY
        context.translateBy(x: CGFloat(transX), y: CGFloat(transY))

        if group.rotation != 0 {
            context.rotate(by: CGFloat(group.rotation * .pi / 180.0))
        }

        if group.scaleX != 1.0 || group.scaleY != 1.0 {
            context.scaleBy(x: CGFloat(group.scaleX), y: CGFloat(group.scaleY))
        }

        if group.pivotX != 0 || group.pivotY != 0 {
            context.translateBy(x: CGFloat(-group.pivotX), y: CGFloat(-group.pivotY))
        }

        for child in group.children {
            renderElement(child, in: context)
        }

        context.restoreGState()
    }

    private func renderPath(_ path: VectorPath, in context: CGContext) {
        guard !path.pathData.isEmpty else { return }
        let cgPath = SVGPathParser.parse(path.pathData)

        // Fill
        if let fillStr = path.fillColor,
           let baseColor = AndroidColor.parse(fillStr, resolver: colorResolver) {
            let fillColor: CGColor
            if path.fillAlpha < 1.0 {
                fillColor = baseColor.copy(alpha: baseColor.alpha * CGFloat(path.fillAlpha)) ?? baseColor
            } else {
                fillColor = baseColor
            }

            context.saveGState()
            context.setFillColor(fillColor)
            context.addPath(cgPath)
            if path.fillType == .evenOdd {
                context.drawPath(using: .eoFill)
            } else {
                context.drawPath(using: .fill)
            }
            context.restoreGState()
        }

        // Stroke
        if let strokeStr = path.strokeColor, path.strokeWidth > 0,
           let baseColor = AndroidColor.parse(strokeStr, resolver: colorResolver) {
            let strokeColor: CGColor
            if path.strokeAlpha < 1.0 {
                strokeColor = baseColor.copy(alpha: baseColor.alpha * CGFloat(path.strokeAlpha)) ?? baseColor
            } else {
                strokeColor = baseColor
            }

            context.saveGState()
            context.setStrokeColor(strokeColor)
            context.setLineWidth(CGFloat(path.strokeWidth))
            context.setLineCap(path.strokeLineCap)
            context.setLineJoin(path.strokeLineJoin)
            context.setMiterLimit(CGFloat(path.strokeMiterLimit))
            context.addPath(cgPath)
            context.drawPath(using: .stroke)
            context.restoreGState()
        }
    }

    private func renderClipPath(_ clip: VectorClipPath, in context: CGContext) {
        guard !clip.pathData.isEmpty else { return }
        let cgPath = SVGPathParser.parse(clip.pathData)
        context.addPath(cgPath)
        context.clip()
    }
}
