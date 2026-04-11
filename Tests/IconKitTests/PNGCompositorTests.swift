import Testing
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
@testable import IconKit

@Suite("PNGCompositor")
struct PNGCompositorTests {

    // MARK: - Helpers

    /// Create a solid-color PNG at the given size.
    private func makePNG(width: Int, height: Int, r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) -> Data {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(srgbRed: r, green: g, blue: b, alpha: a))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = context.makeImage()!
        let data = NSMutableData()
        let dest = CGImageDestinationCreateWithData(data as CFMutableData, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
        return data as Data
    }

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

    // MARK: - Tests

    @Test("Compositing preserves base image dimensions")
    func preservesDimensions() throws {
        let base = makePNG(width: 100, height: 200, r: 1, g: 0, b: 0, a: 1)
        let overlay = makePNG(width: 100, height: 200, r: 0, g: 0, b: 0, a: 0)

        let result = try PNGCompositor.composite(base: base, overlay: overlay)
        let image = decodeImage(result)
        #expect(image.width == 100)
        #expect(image.height == 200)
    }

    @Test("Transparent overlay preserves base pixels")
    func transparentOverlay() throws {
        let base = makePNG(width: 64, height: 64, r: 1, g: 0, b: 0, a: 1)
        let overlay = makePNG(width: 64, height: 64, r: 0, g: 0, b: 0, a: 0)

        let result = try PNGCompositor.composite(base: base, overlay: overlay)
        let image = decodeImage(result)
        let pixel = samplePixel(image, x: 32, y: 32)
        #expect(pixel.r > 0.9)
        #expect(pixel.g < 0.1)
        #expect(pixel.a > 0.9)
    }

    @Test("Opaque overlay covers base pixels")
    func opaqueOverlay() throws {
        let base = makePNG(width: 64, height: 64, r: 1, g: 0, b: 0, a: 1)
        let overlay = makePNG(width: 64, height: 64, r: 0, g: 0, b: 1, a: 1)

        let result = try PNGCompositor.composite(base: base, overlay: overlay)
        let image = decodeImage(result)
        let pixel = samplePixel(image, x: 32, y: 32)
        #expect(pixel.r < 0.1)
        #expect(pixel.b > 0.9)
        #expect(pixel.a > 0.9)
    }

    @Test("Different-sized overlay is scaled to base dimensions")
    func scaledOverlay() throws {
        let base = makePNG(width: 128, height: 128, r: 0, g: 1, b: 0, a: 1)
        let overlay = makePNG(width: 64, height: 64, r: 0, g: 0, b: 1, a: 1)

        let result = try PNGCompositor.composite(base: base, overlay: overlay)
        let image = decodeImage(result)
        #expect(image.width == 128)
        #expect(image.height == 128)
        // Overlay should cover everything since it's scaled up
        let pixel = samplePixel(image, x: 64, y: 64)
        #expect(pixel.b > 0.9)
    }

    // MARK: - ImageFormat detection

    @Test("ImageFormat detects PNG data")
    func detectPNG() {
        let data = makePNG(width: 8, height: 8, r: 0, g: 0, b: 0, a: 1)
        #expect(ImageFormat.detect(from: data) == .png)
    }

    @Test("ImageFormat returns nil for invalid data")
    func detectInvalid() {
        #expect(ImageFormat.detect(from: Data([0, 1, 2])) == nil)
    }

    // MARK: - Error cases

    @Test("Invalid base data throws")
    func invalidBase() throws {
        let overlay = makePNG(width: 64, height: 64, r: 0, g: 0, b: 0, a: 0)
        #expect(throws: PNGCompositorError.self) {
            try PNGCompositor.composite(base: Data([0, 1, 2]), overlay: overlay)
        }
    }

    @Test("Invalid overlay data throws")
    func invalidOverlay() throws {
        let base = makePNG(width: 64, height: 64, r: 1, g: 0, b: 0, a: 1)
        #expect(throws: PNGCompositorError.self) {
            try PNGCompositor.composite(base: base, overlay: Data([0, 1, 2]))
        }
    }
}
