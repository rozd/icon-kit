import Testing
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
@testable import IconKit

@Suite("AdaptiveIconFile+Ribbon")
struct AdaptiveIconFileRibbonTests {

    // MARK: - Helpers

    /// Create a dummy AdaptiveIconFile in memory for testing ribbon application.
    private func makeAdaptiveIconFile(
        densities: [String: Int],
        legacy: [String: [String: Int]] = [:]
    ) -> AdaptiveIconFile {
        let descriptor = AdaptiveIcon(
            background: "@color/ic_launcher_background",
            foreground: "@drawable/ic_launcher_foreground"
        )
        let xmlData = descriptor.xmlData()

        var foregroundImages: [String: Data] = [:]
        for (dirName, size) in densities {
            foregroundImages[dirName] = makePNG(width: size, height: size, r: 1, g: 1, b: 1)
        }

        var legacyIcons: [String: [String: Data]] = [:]
        var legacyExtensions: [String: [String: String]] = [:]
        for (iconName, densitySizes) in legacy {
            var densityMap: [String: Data] = [:]
            var extMap: [String: String] = [:]
            for (dirName, size) in densitySizes {
                densityMap[dirName] = makePNG(width: size, height: size, r: 1, g: 1, b: 1)
                extMap[dirName] = "webp"
            }
            legacyIcons[iconName] = densityMap
            legacyExtensions[iconName] = extMap
        }

        return AdaptiveIconFile(
            descriptor: descriptor,
            xmlData: xmlData,
            xmlRelativePath: "mipmap-anydpi-v26/ic_launcher.xml",
            resDirectory: URL(fileURLWithPath: "/dummy"),
            foregroundImages: foregroundImages,
            backgroundImages: [:],
            legacyIcons: legacyIcons,
            legacyExtensions: legacyExtensions
        )
    }

    private func makePNG(width: Int, height: Int, r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) -> Data {
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
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(CGColor(srgbRed: r, green: g, blue: b, alpha: a))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = context.makeImage()!
        let data = NSMutableData()
        let dest = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        )!
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
        return data as Data
    }

    private func makeInsetPNG(width: Int, height: Int, inset: Int) -> CGImage {
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
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: inset, y: inset, width: width - inset * 2, height: height - inset * 2))
        return context.makeImage()!
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
        let a = CGFloat(pixel[3]) / 255.0
        let r = a > 0 ? (CGFloat(pixel[0]) / 255.0) / a : 0
        let g = a > 0 ? (CGFloat(pixel[1]) / 255.0) / a : 0
        let b = a > 0 ? (CGFloat(pixel[2]) / 255.0) / a : 0
        return (r: r, g: g, b: b, a: a)
    }

    // MARK: - Tests

    @Test("applyRibbon modifies all foreground density variants")
    func modifiesAllDensities() throws {
        var file = makeAdaptiveIconFile(densities: [
            "drawable-mdpi": 108,
            "drawable-hdpi": 162,
            "drawable-xhdpi": 216,
            "drawable-xxhdpi": 324,
            "drawable-xxxhdpi": 432,
        ])

        let originalData = file.foregroundImages["drawable-xxxhdpi"]!

        let style = RibbonStyle(text: "DEV")
        try file.applyRibbon(placement: .bottom, style: style)

        #expect(file.foregroundImages.count == 5)
        #expect(file.foregroundImages["drawable-xxxhdpi"]! != originalData)
    }

    @Test("Result dimensions match originals")
    func dimensionsPreserved() throws {
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
        // Safe-zone bottom area (within 72dp viewport) should have red ribbon pixels
        let bottomPixel = samplePixel(image, x: 162, y: 240)
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

    @Test("applyRibbon updates legacy launcher icons and converts extensions")
    func legacyIconsUpdated() throws {
        var file = makeAdaptiveIconFile(
            densities: ["drawable-hdpi": 162],
            legacy: [
                "ic_launcher": ["mipmap-hdpi": 72],
                "ic_launcher_round": ["mipmap-hdpi": 72],
            ]
        )

        let style = RibbonStyle(text: "DEV")
        try file.applyRibbon(placement: .bottom, style: style)

        #expect(file.legacyIcons["ic_launcher"]?["mipmap-hdpi"] != nil)
        #expect(file.legacyIcons["ic_launcher_round"]?["mipmap-hdpi"] != nil)
        #expect(file.legacyExtensions["ic_launcher"]?["mipmap-hdpi"] == "png")
        #expect(file.legacyExtensions["ic_launcher_round"]?["mipmap-hdpi"] == "png")
    }

    @Test("findContentBounds detects non-transparent area")
    func testFindContentBounds() {
        let image = makeInsetPNG(width: 100, height: 100, inset: 10)
        let bounds = AdaptiveIconFile.findContentBounds(image)

        #expect(bounds.origin.x == 10)
        #expect(bounds.origin.y == 10)
        #expect(bounds.width == 80)
        #expect(bounds.height == 80)
    }

    @Test("findContentBounds on fully transparent image returns full canvas")
    func testFindContentBoundsTransparent() {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CGContext(
            data: nil, width: 64, height: 64,
            bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.clear(CGRect(x: 0, y: 0, width: 64, height: 64))
        let emptyImage = context.makeImage()!

        let bounds = AdaptiveIconFile.findContentBounds(emptyImage)
        #expect(bounds.width == 64)
        #expect(bounds.height == 64)
    }

    // MARK: - WebP input handling

    @Test("applyRibbon converts WebP-origin foreground to PNG and updates extension")
    func webPConvertedToPNG() throws {
        var file = makeAdaptiveIconFile(densities: ["mipmap-hdpi": 162])
        file.foregroundExtensions["mipmap-hdpi"] = "webp"

        let style = RibbonStyle(text: "DEV")
        try file.applyRibbon(placement: .bottom, style: style)

        #expect(file.foregroundExtensions["mipmap-hdpi"] == "png")

        let resultFormat = ImageFormat.detect(from: file.foregroundImages["mipmap-hdpi"]!)
        #expect(resultFormat == .png)

        let image = decodeImage(file.foregroundImages["mipmap-hdpi"]!)
        #expect(image.width == 162)
        #expect(image.height == 162)
    }
}
