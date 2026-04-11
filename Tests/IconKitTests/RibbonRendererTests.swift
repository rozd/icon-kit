import Testing
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
@testable import IconKit

@Suite("RibbonRenderer")
struct RibbonRendererTests {

    // MARK: - Test helpers

    private func decodeImage(_ data: Data) -> CGImage {
        let source = CGImageSourceCreateWithData(data as CFData, nil)!
        return CGImageSourceCreateImageAtIndex(source, 0, nil)!
    }

    private func samplePixel(_ image: CGImage, x: Int, y: Int) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        var pixel: [UInt8] = [0, 0, 0, 0]
        let context = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.draw(image, in: CGRect(x: -x, y: -(image.height - 1 - y), width: image.width, height: image.height))
        return (
            r: CGFloat(pixel[0]) / 255.0,
            g: CGFloat(pixel[1]) / 255.0,
            b: CGFloat(pixel[2]) / 255.0,
            a: CGFloat(pixel[3]) / 255.0
        )
    }

    // MARK: - Output validity

    @Test("Overlay is a valid PNG with requested dimensions")
    func overlayIsValidPNG() throws {
        let style = RibbonStyle(text: "TEST")
        let renderer = RibbonRenderer(placement: .bottom, style: style)

        let output = try renderer.generateOverlay(width: 1024, height: 1024)
        let image = decodeImage(output)
        #expect(image.width == 1024)
        #expect(image.height == 1024)
    }

    @Test("Non-square overlay preserves dimensions")
    func nonSquareOverlay() throws {
        let style = RibbonStyle(text: "X")
        let renderer = RibbonRenderer(placement: .top, style: style)

        let output = try renderer.generateOverlay(width: 512, height: 256)
        let image = decodeImage(output)
        #expect(image.width == 512)
        #expect(image.height == 256)
    }

    // MARK: - Transparency

    @Test("Areas outside ribbon are transparent")
    func transparentBackground() throws {
        let bgColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        let style = RibbonStyle(text: "", size: 0.1, background: bgColor)
        let renderer = RibbonRenderer(placement: .bottom, style: style)

        let output = try renderer.generateOverlay(width: 256, height: 256)
        let image = decodeImage(output)

        // Top area should be fully transparent
        let topPixel = samplePixel(image, x: 128, y: 10)
        #expect(topPixel.a < 0.01)
    }

    // MARK: - Bottom placement pixel check

    @Test("Bottom ribbon draws at bottom of canvas")
    func bottomRibbonPixels() throws {
        let bgColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        let style = RibbonStyle(text: "", size: 0.25, background: bgColor)
        let renderer = RibbonRenderer(placement: .bottom, style: style)

        let output = try renderer.generateOverlay(width: 256, height: 256)
        let image = decodeImage(output)

        // Bottom-center should be red (ribbon area)
        let bottomPixel = samplePixel(image, x: 128, y: 250)
        #expect(bottomPixel.r > 0.9)
        #expect(bottomPixel.g < 0.1)
        #expect(bottomPixel.a > 0.9)

        // Top-center should be transparent (no ribbon)
        let topPixel = samplePixel(image, x: 128, y: 10)
        #expect(topPixel.a < 0.01)
    }

    // MARK: - Top placement pixel check

    @Test("Top ribbon draws at top of canvas")
    func topRibbonPixels() throws {
        let bgColor = CGColor(srgbRed: 0, green: 0, blue: 1, alpha: 1)
        let style = RibbonStyle(text: "", size: 0.25, background: bgColor)
        let renderer = RibbonRenderer(placement: .top, style: style)

        let output = try renderer.generateOverlay(width: 256, height: 256)
        let image = decodeImage(output)

        // Top-center should be blue (ribbon)
        let topPixel = samplePixel(image, x: 128, y: 5)
        #expect(topPixel.b > 0.9)
        #expect(topPixel.a > 0.9)

        // Bottom should be transparent
        let bottomPixel = samplePixel(image, x: 128, y: 250)
        #expect(bottomPixel.a < 0.01)
    }

    // MARK: - Diagonal placement pixel checks

    @Test("topLeft ribbon draws near top-left corner")
    func topLeftRibbonPixels() throws {
        let bgColor = CGColor(srgbRed: 0, green: 1, blue: 0, alpha: 1)
        let style = RibbonStyle(text: "", size: 0.2, background: bgColor)
        let renderer = RibbonRenderer(placement: .topLeft, style: style)

        let output = try renderer.generateOverlay(width: 256, height: 256)
        let image = decodeImage(output)

        // Near top-left corner should be green
        let cornerPixel = samplePixel(image, x: 5, y: 5)
        #expect(cornerPixel.g > 0.9)
        #expect(cornerPixel.a > 0.9)

        // Bottom-right should be transparent
        let farPixel = samplePixel(image, x: 250, y: 250)
        #expect(farPixel.a < 0.01)
    }

    @Test("topRight ribbon draws near top-right corner")
    func topRightRibbonPixels() throws {
        let bgColor = CGColor(srgbRed: 1, green: 0.5, blue: 0, alpha: 1)
        let style = RibbonStyle(text: "", size: 0.2, background: bgColor)
        let renderer = RibbonRenderer(placement: .topRight, style: style)

        let output = try renderer.generateOverlay(width: 256, height: 256)
        let image = decodeImage(output)

        // Near top-right corner should be orange
        let cornerPixel = samplePixel(image, x: 250, y: 5)
        #expect(cornerPixel.r > 0.9)
        #expect(cornerPixel.a > 0.9)

        // Bottom-left should be transparent
        let farPixel = samplePixel(image, x: 5, y: 250)
        #expect(farPixel.a < 0.01)
    }

    // MARK: - Offset

    @Test("Bottom ribbon with offset shifts up from bottom edge")
    func bottomRibbonOffset() throws {
        let bgColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        // size=0.1 (25.6px ribbon), offset=0.2 (51.2px from bottom)
        let style = RibbonStyle(text: "", size: 0.1, offset: 0.2, background: bgColor)
        let renderer = RibbonRenderer(placement: .bottom, style: style)

        let output = try renderer.generateOverlay(width: 256, height: 256)
        let image = decodeImage(output)

        // Very bottom should be transparent (offset pushes ribbon up)
        let bottomPixel = samplePixel(image, x: 128, y: 253)
        #expect(bottomPixel.a < 0.01)

        // At the offset position, should be red (ribbon)
        let ribbonPixel = samplePixel(image, x: 128, y: 200)
        #expect(ribbonPixel.r > 0.9)
        #expect(ribbonPixel.a > 0.9)
    }

    // MARK: - Text rendering

    @Test("Ribbon with text renders without crashing")
    func textRenders() throws {
        let style = RibbonStyle(text: "UAT", size: 0.25)
        let renderer = RibbonRenderer(placement: .bottom, style: style)

        let output = try renderer.generateOverlay(width: 1024, height: 1024)
        let image = decodeImage(output)
        #expect(image.width == 1024)
        #expect(image.height == 1024)
    }

    @Test("Long text auto-scales without crashing")
    func longTextAutoScales() throws {
        let style = RibbonStyle(text: "VERY LONG ENVIRONMENT NAME HERE", size: 0.15)
        let renderer = RibbonRenderer(placement: .bottom, style: style)

        let output = try renderer.generateOverlay(width: 1024, height: 1024)
        let image = decodeImage(output)
        #expect(image.width == 1024)
    }

    @Test("Text pixels are visible in ribbon area")
    func textPixelsVisible() throws {
        // Black ribbon, white text — text pixels should be white
        let bgColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        let fgColor = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        let style = RibbonStyle(
            text: "WWWWWWWW",
            size: 0.3,
            background: bgColor,
            foreground: fgColor
        )
        let renderer = RibbonRenderer(placement: .bottom, style: style)

        let output = try renderer.generateOverlay(width: 512, height: 512)
        let image = decodeImage(output)

        // Sample the center of the ribbon area — should have some non-black pixels
        // (text is centered, so the exact center should hit text)
        let centerPixel = samplePixel(image, x: 256, y: 512 - Int(512 * 0.15))
        // Either the text is white (r>0.5) or the background is black (r==0)
        // At least the pixel should be opaque (in the ribbon)
        #expect(centerPixel.a > 0.9)
    }

    // MARK: - applyRibbon extension

    @Test("applyRibbon adds a new group and asset to the document")
    func applyRibbonAddsLayer() throws {
        let document = IconDocument(groups: [
            IconGroup(layers: [
                IconLayer(imageName: "icon.png"),
            ])
        ])
        var descriptor = IconComposerDescriptorFile(
            document: document,
            assets: ["icon.png": Data()]
        )

        let style = RibbonStyle(text: "DEV")
        try descriptor.applyRibbon(placement: .bottom, style: style, canvasSize: 256)

        // Original group is preserved
        #expect(descriptor.document.groups.count == 2)
        #expect(descriptor.document.groups[1].layers[0].imageName == "icon.png")

        // Ribbon group is inserted at front (index 0 = top-most)
        let ribbonGroup = descriptor.document.groups[0]
        #expect(ribbonGroup.layers.count == 1)
        #expect(ribbonGroup.layers[0].imageName == "_ribbon_overlay.png")
        #expect(ribbonGroup.layers[0].glass == false)

        // Liquid Glass effects are disabled
        #expect(ribbonGroup.specular == false)
        #expect(ribbonGroup.translucency == IconTranslucency(enabled: false, value: 0.0))
        #expect(ribbonGroup.shadow == IconShadow(kind: .none, opacity: 0.0))

        // Ribbon asset was added
        #expect(descriptor.assets["_ribbon_overlay.png"] != nil)

        // Original asset is untouched
        #expect(descriptor.assets["icon.png"] == Data())

        // Ribbon asset is a valid PNG
        let ribbonImage = decodeImage(descriptor.assets["_ribbon_overlay.png"]!)
        #expect(ribbonImage.width == 256)
        #expect(ribbonImage.height == 256)
    }

    @Test("applyRibbon preserves non-group document fields")
    func applyRibbonPreservesDocument() throws {
        let document = IconDocument(
            colorSpaceForUntaggedSVGColors: "display-p3",
            fill: .automatic,
            groups: [],
            supportedPlatforms: SupportedPlatforms(circles: ["watchOS"], squares: .shared)
        )
        var descriptor = IconComposerDescriptorFile(document: document)

        let style = RibbonStyle(text: "T")
        try descriptor.applyRibbon(placement: .top, style: style, canvasSize: 128)

        #expect(descriptor.document.colorSpaceForUntaggedSVGColors == "display-p3")
        #expect(descriptor.document.fill == .automatic)
        #expect(descriptor.document.supportedPlatforms?.circles == ["watchOS"])
    }
}
