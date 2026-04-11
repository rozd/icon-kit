import Testing
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
@testable import IconKit

@Suite("SFSymbolRenderer")
struct SFSymbolRendererTests {

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

    /// Returns true if any pixel in the given column range and row range is opaque.
    private func hasOpaquePixels(
        _ image: CGImage,
        xRange: ClosedRange<Int>,
        yRange: ClosedRange<Int>,
        step: Int = 4
    ) -> Bool {
        for y in stride(from: yRange.lowerBound, through: yRange.upperBound, by: step) {
            for x in stride(from: xRange.lowerBound, through: xRange.upperBound, by: step) {
                if samplePixel(image, x: x, y: y).a > 0.1 {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - Output validity

    @Test("Render produces a valid PNG with requested dimensions")
    func renderProducesValidPNG() throws {
        let style = SFSymbolStyle(
            symbolName: "star.fill",
            foreground: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        )
        let renderer = SFSymbolRenderer(style: style)
        let output = try renderer.render(canvasSize: 1024)
        let image = decodeImage(output)
        #expect(image.width == 1024)
        #expect(image.height == 1024)
    }

    @Test("Render at smaller canvas size works")
    func renderSmallCanvas() throws {
        let style = SFSymbolStyle(
            symbolName: "star.fill",
            foreground: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        )
        let renderer = SFSymbolRenderer(style: style)
        let output = try renderer.render(canvasSize: 256)
        let image = decodeImage(output)
        #expect(image.width == 256)
        #expect(image.height == 256)
    }

    // MARK: - Symbol rendering

    @Test("Symbol renders non-transparent pixels in center area")
    func symbolRendersContent() throws {
        let style = SFSymbolStyle(
            symbolName: "star.fill",
            foreground: CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1),
            size: 0.8
        )
        let renderer = SFSymbolRenderer(style: style)
        let output = try renderer.render(canvasSize: 256)
        let image = decodeImage(output)

        // Center area should have opaque pixels (the symbol)
        let centerHasContent = hasOpaquePixels(image, xRange: 96...160, yRange: 96...160)
        #expect(centerHasContent)
    }

    @Test("Corners are transparent when symbol is centered")
    func cornersTransparent() throws {
        let style = SFSymbolStyle(
            symbolName: "circle.fill",
            foreground: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1),
            size: 0.5
        )
        let renderer = SFSymbolRenderer(style: style)
        let output = try renderer.render(canvasSize: 256)
        let image = decodeImage(output)

        // All four corners should be transparent
        #expect(samplePixel(image, x: 2, y: 2).a < 0.01)
        #expect(samplePixel(image, x: 253, y: 2).a < 0.01)
        #expect(samplePixel(image, x: 2, y: 253).a < 0.01)
        #expect(samplePixel(image, x: 253, y: 253).a < 0.01)
    }

    @Test("Foreground color is applied to symbol")
    func foregroundColorApplied() throws {
        let style = SFSymbolStyle(
            symbolName: "circle.fill",
            foreground: CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1),
            size: 0.8
        )
        let renderer = SFSymbolRenderer(style: style)
        let output = try renderer.render(canvasSize: 256)
        let image = decodeImage(output)

        // Center pixel should be red
        let center = samplePixel(image, x: 128, y: 128)
        #expect(center.r > 0.8)
        #expect(center.g < 0.2)
        #expect(center.b < 0.2)
        #expect(center.a > 0.8)
    }

    // MARK: - Size parameter

    @Test("Larger size fills more of the canvas")
    func largerSizeCoversMore() throws {
        let fgColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)

        let smallStyle = SFSymbolStyle(symbolName: "square.fill", foreground: fgColor, size: 0.3)
        let largeStyle = SFSymbolStyle(symbolName: "square.fill", foreground: fgColor, size: 0.9)

        let smallOutput = try SFSymbolRenderer(style: smallStyle).render(canvasSize: 256)
        let largeOutput = try SFSymbolRenderer(style: largeStyle).render(canvasSize: 256)

        let smallImage = decodeImage(smallOutput)
        let largeImage = decodeImage(largeOutput)

        // With size=0.3, a point near the edge should be transparent
        let edgePixelSmall = samplePixel(smallImage, x: 50, y: 128)
        #expect(edgePixelSmall.a < 0.1)

        // With size=0.9, the same point should be opaque
        let edgePixelLarge = samplePixel(largeImage, x: 50, y: 128)
        #expect(edgePixelLarge.a > 0.5)
    }

    // MARK: - Offset

    @Test("Positive offsetX shifts symbol to the right")
    func offsetXShiftsRight() throws {
        let fgColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)

        let centeredStyle = SFSymbolStyle(symbolName: "circle.fill", foreground: fgColor, size: 0.3)
        let shiftedStyle = SFSymbolStyle(symbolName: "circle.fill", foreground: fgColor, size: 0.3, offsetX: 0.3)

        let centeredOutput = try SFSymbolRenderer(style: centeredStyle).render(canvasSize: 256)
        let shiftedOutput = try SFSymbolRenderer(style: shiftedStyle).render(canvasSize: 256)

        let centeredImage = decodeImage(centeredOutput)
        let shiftedImage = decodeImage(shiftedOutput)

        // Far right area: centered should be empty, shifted should have content
        let rightAreaCentered = hasOpaquePixels(centeredImage, xRange: 200...240, yRange: 120...136)
        let rightAreaShifted = hasOpaquePixels(shiftedImage, xRange: 200...240, yRange: 120...136)

        #expect(!rightAreaCentered)
        #expect(rightAreaShifted)
    }

    // MARK: - Error cases

    @Test("Invalid symbol name throws symbolNotFound")
    func invalidSymbolThrows() {
        let style = SFSymbolStyle(
            symbolName: "this.symbol.definitely.does.not.exist.12345",
            foreground: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        )
        let renderer = SFSymbolRenderer(style: style)
        #expect(throws: SFSymbolRendererError.self) {
            try renderer.render(canvasSize: 256)
        }
    }

    // MARK: - SFSymbolStyle defaults

    @Test("SFSymbolStyle has expected defaults")
    func styleDefaults() {
        let fg = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        let style = SFSymbolStyle(symbolName: "star", foreground: fg)
        #expect(style.symbolName == "star")
        #expect(style.size == 0.6)
        #expect(style.offsetX == 0.0)
        #expect(style.offsetY == 0.0)
    }

    // MARK: - IconComposerDescriptorFile.sfSymbol integration

    @Test("sfSymbol factory creates correct document structure")
    func sfSymbolFactoryDocumentStructure() throws {
        let style = SFSymbolStyle(
            symbolName: "star.fill",
            foreground: CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1),
            size: 0.7
        )
        let background = IconColor(colorSpace: .sRGB, components: [0.0, 0.5, 1.0, 1.0])
        let descriptor = try IconComposerDescriptorFile.sfSymbol(
            style: style,
            background: background
        )

        // Document fill is the background color
        #expect(descriptor.document.fill == .solid(background))

        // One group with one layer
        #expect(descriptor.document.groups.count == 1)
        #expect(descriptor.document.groups[0].layers.count == 1)
        #expect(descriptor.document.groups[0].layers[0].imageName == "Symbol.png")
    }

    @Test("sfSymbol factory includes valid PNG asset")
    func sfSymbolFactoryAsset() throws {
        let style = SFSymbolStyle(
            symbolName: "star.fill",
            foreground: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        )
        let background = IconColor(colorSpace: .sRGB, components: [1.0, 1.0, 1.0, 1.0])
        let descriptor = try IconComposerDescriptorFile.sfSymbol(
            style: style,
            background: background,
            canvasSize: 512
        )

        // Asset exists
        let assetData = descriptor.assets["Symbol.png"]
        #expect(assetData != nil)

        // Asset is a valid PNG with correct dimensions
        let image = decodeImage(assetData!)
        #expect(image.width == 512)
        #expect(image.height == 512)
    }

    @Test("sfSymbol factory passes asset validation")
    func sfSymbolFactoryValidation() throws {
        let style = SFSymbolStyle(
            symbolName: "star.fill",
            foreground: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        )
        let background = IconColor(colorSpace: .sRGB, components: [0.0, 0.0, 0.0, 1.0])
        let descriptor = try IconComposerDescriptorFile.sfSymbol(
            style: style,
            background: background,
            canvasSize: 256
        )

        // All referenced assets should be present
        let missing = descriptor.validateAssets()
        #expect(missing.isEmpty)
    }
}
