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
        for (density, imageData) in foregroundImages {
            let (width, height) = try imageDimensions(imageData)
            let overlay = try renderer.generateOverlay(width: width, height: height)
            foregroundImages[density] = try ImageCompositor.composite(
                base: imageData, overlay: overlay
            )
            // Composited output is always PNG (WebP encoding unavailable via ImageIO)
            foregroundExtensions[density] = "png"
        }

        // 2. Composite ribbon onto legacy launcher icons (ic_launcher, ic_launcher_round, etc.)
        for (iconName, densityMap) in legacyIcons {
            var updatedMap: [String: Data] = [:]
            for (density, imageData) in densityMap {
                let (width, height) = try imageDimensions(imageData)
                let overlay = try renderer.generateOverlay(width: width, height: height)
                updatedMap[density] = try ImageCompositor.composite(
                    base: imageData, overlay: overlay
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
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw PNGCompositorError.cannotDecodeImage("image")
        }
        return (image.width, image.height)
    }
}
