import CoreGraphics
import Foundation
import ImageIO

extension AdaptiveIconFile {

    /// Apply a ribbon overlay to this adaptive icon by compositing it onto
    /// every density variant of the foreground layer and any legacy launcher icons.
    ///
    /// Because Android adaptive icons only support foreground + background layers,
    /// the ribbon cannot be added as a separate layer. Instead, it is rendered
    /// at each foreground image's resolution and composited on top.
    ///
    /// - Parameters:
    ///   - placement: Where to position the ribbon.
    ///   - style: Visual configuration for the ribbon.
    public mutating func applyRibbon(
        placement: RibbonPlacement,
        style: RibbonStyle
    ) throws {
        guard !foregroundImages.isEmpty else {
            throw AdaptiveIconError.noForegroundImages
        }

        let renderer = RibbonRenderer(placement: placement, style: style)

        // 1. Composite ribbon onto adaptive icon foreground images
        // In Android adaptive icons, canvas is 108dp, but the visible icon mask is the center 72dp (18dp margins)
        for (density, imageData) in foregroundImages {
            let (width, height) = try imageDimensions(imageData)
            let viewport = CGRect(
                x: Double(width) * (18.0 / 108.0),
                y: Double(height) * (18.0 / 108.0),
                width: Double(width) * (72.0 / 108.0),
                height: Double(height) * (72.0 / 108.0)
            )
            let overlay = try renderer.generateOverlay(
                width: width,
                height: height,
                viewport: viewport
            )
            foregroundImages[density] = try ImageCompositor.composite(
                base: imageData, overlay: overlay
            )
            foregroundExtensions[density] = "png"
        }

        // 2. Composite ribbon onto legacy launcher icons (ic_launcher, ic_launcher_round, etc.)
        for (iconName, densityMap) in legacyIcons {
            var updatedMap: [String: Data] = [:]
            for (density, imageData) in densityMap {
                let cgImage = try decodeCGImage(imageData)
                let width = cgImage.width
                let height = cgImage.height
                let contentBounds = Self.findContentBounds(cgImage)
                let overlay = try renderer.generateOverlay(
                    width: width,
                    height: height,
                    viewport: contentBounds
                )
                updatedMap[density] = try ImageCompositor.composite(
                    base: imageData, overlay: overlay, maskToBaseAlpha: true
                )
                if legacyExtensions[iconName] == nil {
                    legacyExtensions[iconName] = [:]
                }
                legacyExtensions[iconName]?[density] = "png"
            }
            legacyIcons[iconName] = updatedMap
        }
    }

    /// Read the pixel dimensions of an image from its data.
    private func imageDimensions(_ data: Data) throws -> (width: Int, height: Int) {
        let image = try decodeCGImage(data)
        return (image.width, image.height)
    }

    private func decodeCGImage(_ data: Data) throws -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw PNGCompositorError.cannotDecodeImage("image")
        }
        return image
    }

    /// Find the non-transparent content bounding box of a CGImage (alpha > 10%).
    public static func findContentBounds(_ image: CGImage) -> CGRect {
        let width = image.width
        let height = image.height
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: width * 4,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return CGRect(x: 0, y: 0, width: width, height: height)
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let pixelData = context.data else {
            return CGRect(x: 0, y: 0, width: width, height: height)
        }

        let ptr = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)

        var minX = width
        var maxX = 0
        var minY = height
        var maxY = 0

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let alpha = ptr[offset + 3]
                if alpha > 25 {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }

        guard minX <= maxX, minY <= maxY else {
            return CGRect(x: 0, y: 0, width: width, height: height)
        }

        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )
    }
}
