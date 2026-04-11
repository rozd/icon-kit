import CoreGraphics
import Foundation
import ImageIO

extension AdaptiveIconFile {

    /// Apply a ribbon overlay to this adaptive icon by compositing it onto
    /// every density variant of the foreground layer.
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

        for (density, imageData) in foregroundImages {
            let (width, height) = try imageDimensions(imageData)
            let overlay = try renderer.generateOverlay(width: width, height: height)
            foregroundImages[density] = try ImageCompositor.composite(
                base: imageData, overlay: overlay
            )
            // Composited output is always PNG (WebP encoding unavailable via ImageIO)
            foregroundExtensions[density] = "png"
        }
    }

    /// Read the pixel dimensions of a PNG from its data.
    private func imageDimensions(_ data: Data) throws -> (width: Int, height: Int) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw PNGCompositorError.cannotDecodeImage("foreground")
        }
        return (image.width, image.height)
    }
}
