import Testing
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
@testable import IconKit

@Suite("AdaptiveIconVector")
struct AdaptiveIconVectorTests {

    private func makeTempResDir() throws -> URL {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("AdaptiveIconVectorTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        return tmp
    }

    private func makePNG(width: Int, height: Int) -> Data {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(srgbRed: 0, green: 0.5, blue: 1, alpha: 1))
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

    /// Creates a modern Android res/ directory mimicking Android Studio template (and fitnessart-android).
    private func createModernAndroidRes(at resDir: URL) throws {
        let fm = FileManager.default

        // 1. mipmap-anydpi-v26/ic_launcher.xml and ic_launcher_round.xml
        let anydpiDir = resDir.appendingPathComponent("mipmap-anydpi-v26")
        try fm.createDirectory(at: anydpiDir, withIntermediateDirectories: true)

        let adaptiveXML = """
        <?xml version="1.0" encoding="utf-8"?>
        <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
            <background android:drawable="@color/ic_launcher_background"/>
            <foreground android:drawable="@drawable/ic_launcher_foreground"/>
            <monochrome android:drawable="@drawable/ic_launcher_foreground"/>
        </adaptive-icon>
        """
        try Data(adaptiveXML.utf8).write(to: anydpiDir.appendingPathComponent("ic_launcher.xml"))
        try Data(adaptiveXML.utf8).write(to: anydpiDir.appendingPathComponent("ic_launcher_round.xml"))

        // 2. drawable/ic_launcher_foreground.xml (Vector Drawable)
        let drawableDir = resDir.appendingPathComponent("drawable")
        try fm.createDirectory(at: drawableDir, withIntermediateDirectories: true)

        let vectorXML = """
        <vector xmlns:android="http://schemas.android.com/apk/res/android"
            android:width="108dp"
            android:height="108dp"
            android:viewportWidth="108"
            android:viewportHeight="108">
            <path
                android:fillColor="#FF0000"
                android:pathData="M10,10h88v88h-88z"/>
        </vector>
        """
        try Data(vectorXML.utf8).write(to: drawableDir.appendingPathComponent("ic_launcher_foreground.xml"))

        // 3. values/ic_launcher_background.xml
        let valuesDir = resDir.appendingPathComponent("values")
        try fm.createDirectory(at: valuesDir, withIntermediateDirectories: true)

        let valuesXML = """
        <?xml version="1.0" encoding="utf-8"?>
        <resources>
            <color name="ic_launcher_background">#B2A69A</color>
        </resources>
        """
        try Data(valuesXML.utf8).write(to: valuesDir.appendingPathComponent("ic_launcher_background.xml"))

        // 4. Legacy mipmap densities
        for (suffix, _, _, legacySize) in AdaptiveIconFile.standardDensities {
            let densityDir = resDir.appendingPathComponent("mipmap-\(suffix)")
            try fm.createDirectory(at: densityDir, withIntermediateDirectories: true)
            let imgData = makePNG(width: legacySize, height: legacySize)
            try imgData.write(to: densityDir.appendingPathComponent("ic_launcher.webp"))
            try imgData.write(to: densityDir.appendingPathComponent("ic_launcher_round.webp"))
        }
    }

    @Test("Read modern Android res with Vector Drawable foreground")
    func readModernRes() throws {
        let resDir = try makeTempResDir()
        defer { try? FileManager.default.removeItem(at: resDir) }
        try createModernAndroidRes(at: resDir)

        let file = try AdaptiveIconFile(contentsOf: resDir)
        #expect(file.isForegroundVector == true)
        #expect(file.descriptor.foreground == "@drawable/ic_launcher_foreground")
        #expect(file.descriptor.background == "@color/ic_launcher_background")

        // Should have rendered all 5 standard densities
        #expect(file.foregroundImages.count == 5)
        #expect(file.foregroundImages["drawable-mdpi"] != nil)
        #expect(file.foregroundImages["drawable-hdpi"] != nil)
        #expect(file.foregroundImages["drawable-xhdpi"] != nil)
        #expect(file.foregroundImages["drawable-xxhdpi"] != nil)
        #expect(file.foregroundImages["drawable-xxxhdpi"] != nil)

        // Should have discovered legacy icons
        #expect(file.legacyIcons["ic_launcher"] != nil)
        #expect(file.legacyIcons["ic_launcher_round"] != nil)
        #expect(file.legacyIcons["ic_launcher"]?.count == 5)
    }

    @Test("Apply ribbon to modern Android icon and write")
    func applyRibbonAndWrite() throws {
        let resDir = try makeTempResDir()
        let outputDir = try makeTempResDir()
        defer {
            try? FileManager.default.removeItem(at: resDir)
            try? FileManager.default.removeItem(at: outputDir)
        }
        try createModernAndroidRes(at: resDir)

        var file = try AdaptiveIconFile(contentsOf: resDir)
        let style = RibbonStyle(text: "UAT", background: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1))
        try file.applyRibbon(placement: .bottom, style: style)

        try file.write(to: outputDir)

        let fm = FileManager.default

        // XML descriptors should exist
        #expect(fm.fileExists(atPath: outputDir.appendingPathComponent("mipmap-anydpi-v26/ic_launcher.xml").path))
        #expect(fm.fileExists(atPath: outputDir.appendingPathComponent("mipmap-anydpi-v26/ic_launcher_round.xml").path))

        // Vector XML should NOT exist in output (cleaned up so AAPT uses density PNGs)
        #expect(!fm.fileExists(atPath: outputDir.appendingPathComponent("drawable/ic_launcher_foreground.xml").path))

        // Density PNGs should exist for foreground
        for (suffix, _, _, _) in AdaptiveIconFile.standardDensities {
            let pngPath = outputDir.appendingPathComponent("drawable-\(suffix)/ic_launcher_foreground.png").path
            #expect(fm.fileExists(atPath: pngPath))
        }

        // Legacy icons should exist as PNG (and old .webp cleaned up)
        for (suffix, _, _, _) in AdaptiveIconFile.standardDensities {
            let launcherPNG = outputDir.appendingPathComponent("mipmap-\(suffix)/ic_launcher.png").path
            let roundPNG = outputDir.appendingPathComponent("mipmap-\(suffix)/ic_launcher_round.png").path
            #expect(fm.fileExists(atPath: launcherPNG))
            #expect(fm.fileExists(atPath: roundPNG))
        }
    }

    @Test("In-place ribbon modification on modern Android project")
    func inPlaceModification() throws {
        let resDir = try makeTempResDir()
        defer { try? FileManager.default.removeItem(at: resDir) }
        try createModernAndroidRes(at: resDir)

        var file = try AdaptiveIconFile(contentsOf: resDir)
        let style = RibbonStyle(text: "DEV")
        try file.applyRibbon(placement: .bottom, style: style)
        try file.write(to: resDir)

        let fm = FileManager.default

        // Original vector XML was removed
        #expect(!fm.fileExists(atPath: resDir.appendingPathComponent("drawable/ic_launcher_foreground.xml").path))

        // Density PNGs are present
        #expect(fm.fileExists(atPath: resDir.appendingPathComponent("drawable-xxxhdpi/ic_launcher_foreground.png").path))

        // Rereading should succeed cleanly from the modified directory
        let reread = try AdaptiveIconFile(contentsOf: resDir)
        #expect(reread.foregroundImages.count == 5)
    }
}
