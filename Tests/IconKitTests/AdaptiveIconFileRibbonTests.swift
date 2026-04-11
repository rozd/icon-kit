import Testing
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
@testable import IconKit

@Suite("AdaptiveIconFile+Ribbon")
struct AdaptiveIconFileRibbonTests {

    // MARK: - Helpers

    private func makePNG(width: Int, height: Int, r: CGFloat = 0, g: CGFloat = 0.5, b: CGFloat = 1, a: CGFloat = 1) -> Data {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(srgbRed: r, green: g, blue: b, alpha: a))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = context.makeImage()!
        let data = NSMutableData()
        let dest = CGImageDestinationCreateWithData(
            data as CFMutableData, UTType.png.identifier as CFString, 1, nil
        )!
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
            data: &pixel, width: 1, height: 1,
            bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace,
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

    private func makeAdaptiveIconFile(densities: [String: Int]) -> AdaptiveIconFile {
        var foreground: [String: Data] = [:]
        for (density, size) in densities {
            foreground[density] = makePNG(width: size, height: size)
        }
        return AdaptiveIconFile(
            descriptor: AdaptiveIcon(
                background: "@mipmap/bg",
                foreground: "@mipmap/fg"
            ),
            xmlData: AdaptiveIcon(
                background: "@mipmap/bg",
                foreground: "@mipmap/fg"
            ).xmlData(),
            xmlRelativePath: "mipmap-anydpi-v26/ic_launcher.xml",
            resDirectory: URL(fileURLWithPath: "/tmp"),
            foregroundImages: foreground,
            backgroundImages: [:]
        )
    }

    // MARK: - Tests

    @Test("applyRibbon modifies all foreground density variants")
    func modifiesAllDensities() throws {
        var file = makeAdaptiveIconFile(densities: [
            "mipmap-mdpi": 108,
            "mipmap-hdpi": 162,
            "mipmap-xxxhdpi": 432,
        ])

        let originalData = file.foregroundImages
        let style = RibbonStyle(text: "DEV")
        try file.applyRibbon(placement: .bottom, style: style)

        // All densities should be modified
        #expect(file.foregroundImages.count == 3)
        for (density, data) in file.foregroundImages {
            #expect(data != originalData[density])
        }
    }

    @Test("Result dimensions match originals")
    func preservesDimensions() throws {
        var file = makeAdaptiveIconFile(densities: [
            "mipmap-hdpi": 162,
            "mipmap-xxxhdpi": 432,
        ])

        let style = RibbonStyle(text: "QA")
        try file.applyRibbon(placement: .top, style: style)

        let hdpi = decodeImage(file.foregroundImages["mipmap-hdpi"]!)
        #expect(hdpi.width == 162)
        #expect(hdpi.height == 162)

        let xxxhdpi = decodeImage(file.foregroundImages["mipmap-xxxhdpi"]!)
        #expect(xxxhdpi.width == 432)
        #expect(xxxhdpi.height == 432)
    }

    @Test("Result contains ribbon pixels at bottom placement")
    func ribbonPixelsVisible() throws {
        var file = makeAdaptiveIconFile(densities: ["mipmap-xxhdpi": 324])

        let bgColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        let style = RibbonStyle(text: "", size: 0.25, background: bgColor)
        try file.applyRibbon(placement: .bottom, style: style)

        let image = decodeImage(file.foregroundImages["mipmap-xxhdpi"]!)
        // Bottom area should have red ribbon pixels
        let bottomPixel = samplePixel(image, x: 162, y: 320)
        #expect(bottomPixel.r > 0.8)
        #expect(bottomPixel.a > 0.9)
    }

    @Test("Empty foreground images throws noForegroundImages")
    func emptyForegroundThrows() {
        var file = makeAdaptiveIconFile(densities: [:])
        let style = RibbonStyle(text: "X")
        #expect(throws: AdaptiveIconError.self) {
            try file.applyRibbon(placement: .bottom, style: style)
        }
    }

    @Test("Background images are not modified")
    func backgroundUnchanged() throws {
        var file = makeAdaptiveIconFile(densities: ["mipmap-hdpi": 162])
        let bgData = makePNG(width: 162, height: 162, r: 0, g: 1, b: 0)
        file.backgroundImages["mipmap-hdpi"] = bgData

        let style = RibbonStyle(text: "STG")
        try file.applyRibbon(placement: .top, style: style)

        #expect(file.backgroundImages["mipmap-hdpi"] == bgData)
    }

    // MARK: - WebP input handling

    @Test("applyRibbon converts WebP-origin foreground to PNG and updates extension")
    func webPConvertedToPNG() throws {
        // Use PNG data with WebP extension tracking (simulates WebP input)
        var file = makeAdaptiveIconFile(densities: ["mipmap-hdpi": 162])
        file.foregroundExtensions["mipmap-hdpi"] = "webp"

        let style = RibbonStyle(text: "DEV")
        try file.applyRibbon(placement: .bottom, style: style)

        // Extension should be updated to png after compositing
        #expect(file.foregroundExtensions["mipmap-hdpi"] == "png")

        // Output should be valid PNG
        let resultFormat = ImageFormat.detect(from: file.foregroundImages["mipmap-hdpi"]!)
        #expect(resultFormat == .png)

        let image = decodeImage(file.foregroundImages["mipmap-hdpi"]!)
        #expect(image.width == 162)
        #expect(image.height == 162)
    }
}
