import Testing
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
@testable import IconKit

@Suite("AdaptiveIconFile")
struct AdaptiveIconFileTests {

    // MARK: - Helpers

    private func makeTempResDir() throws -> URL {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("AdaptiveIconFileTests-\(UUID().uuidString)")
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

    /// Create a minimal res/ directory with an adaptive icon XML and foreground PNGs.
    private func createSampleRes(
        at resDir: URL,
        densities: [String] = ["mipmap-hdpi", "mipmap-xhdpi", "mipmap-xxhdpi"],
        iconName: String = "ic_launcher",
        fgName: String = "ic_launcher_foreground",
        bgName: String = "ic_launcher_background",
        fgSize: Int = 162,
        bgSize: Int = 162
    ) throws {
        let fm = FileManager.default

        // Write XML
        let anydpiDir = resDir.appendingPathComponent("mipmap-anydpi-v26")
        try fm.createDirectory(at: anydpiDir, withIntermediateDirectories: true)
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
            <background android:drawable="@mipmap/\(bgName)"/>
            <foreground android:drawable="@mipmap/\(fgName)"/>
        </adaptive-icon>
        """
        try Data(xml.utf8).write(to: anydpiDir.appendingPathComponent("\(iconName).xml"))

        // Write density PNGs
        for density in densities {
            let dir = resDir.appendingPathComponent(density)
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            try makePNG(width: fgSize, height: fgSize).write(
                to: dir.appendingPathComponent("\(fgName).png")
            )
            try makePNG(width: bgSize, height: bgSize).write(
                to: dir.appendingPathComponent("\(bgName).png")
            )
        }
    }

    /// Create a res/ directory with .webp-extension assets.
    /// Uses PNG data inside .webp files since WebP encoding isn't available
    /// via ImageIO on macOS. This tests file discovery and extension tracking.
    private func createWebPRes(
        at resDir: URL,
        densities: [String] = ["mipmap-hdpi", "mipmap-xxhdpi"],
        size: Int = 162
    ) throws {
        let fm = FileManager.default

        let anydpiDir = resDir.appendingPathComponent("mipmap-anydpi-v26")
        try fm.createDirectory(at: anydpiDir, withIntermediateDirectories: true)
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
            <background android:drawable="@mipmap/ic_launcher_background"/>
            <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
        </adaptive-icon>
        """
        try Data(xml.utf8).write(to: anydpiDir.appendingPathComponent("ic_launcher.xml"))

        for density in densities {
            let dir = resDir.appendingPathComponent(density)
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            try makePNG(width: size, height: size).write(
                to: dir.appendingPathComponent("ic_launcher_foreground.webp")
            )
            try makePNG(width: size, height: size).write(
                to: dir.appendingPathComponent("ic_launcher_background.webp")
            )
        }
    }

    // MARK: - Reading

    @Test("Read from XML file path resolves foreground images")
    func readFromXMLPath() throws {
        let resDir = try makeTempResDir()
        defer { try? FileManager.default.removeItem(at: resDir) }
        try createSampleRes(at: resDir)

        let xmlPath = resDir
            .appendingPathComponent("mipmap-anydpi-v26")
            .appendingPathComponent("ic_launcher.xml")

        let file = try AdaptiveIconFile(contentsOf: xmlPath)
        #expect(file.descriptor.foreground == "@mipmap/ic_launcher_foreground")
        #expect(file.descriptor.background == "@mipmap/ic_launcher_background")
        #expect(file.foregroundImages.count == 3)
        #expect(file.backgroundImages.count == 3)
    }

    @Test("Read from res/ directory auto-discovers XML")
    func readFromResDir() throws {
        let resDir = try makeTempResDir()
        defer { try? FileManager.default.removeItem(at: resDir) }
        try createSampleRes(at: resDir)

        let file = try AdaptiveIconFile(contentsOf: resDir)
        #expect(file.descriptor.foreground == "@mipmap/ic_launcher_foreground")
        #expect(file.foregroundImages.count == 3)
    }

    @Test("Missing XML file throws xmlNotFound")
    func missingXML() {
        let bogus = URL(fileURLWithPath: "/tmp/does-not-exist.xml")
        #expect(throws: AdaptiveIconError.self) {
            try AdaptiveIconFile(contentsOf: bogus)
        }
    }

    @Test("Missing res/ directory throws")
    func missingResDir() {
        let bogus = URL(fileURLWithPath: "/tmp/nonexistent-res-dir-\(UUID().uuidString)")
        #expect(throws: AdaptiveIconError.self) {
            try AdaptiveIconFile(contentsOf: bogus)
        }
    }

    @Test("Res dir without mipmap-anydpi-v26 throws xmlNotFound")
    func noAnydpiDir() throws {
        let resDir = try makeTempResDir()
        defer { try? FileManager.default.removeItem(at: resDir) }
        // Don't create any subdirectories

        #expect(throws: AdaptiveIconError.self) {
            try AdaptiveIconFile(contentsOf: resDir)
        }
    }

    // MARK: - Writing

    @Test("Write and read round-trips foreground images")
    func writeRoundTrip() throws {
        let resDir = try makeTempResDir()
        let outputDir = try makeTempResDir()
        defer {
            try? FileManager.default.removeItem(at: resDir)
            try? FileManager.default.removeItem(at: outputDir)
        }
        try createSampleRes(at: resDir, densities: ["mipmap-hdpi", "mipmap-xxhdpi"])

        let file = try AdaptiveIconFile(contentsOf: resDir)
        try file.write(to: outputDir)

        let reread = try AdaptiveIconFile(contentsOf: outputDir)
        #expect(reread.descriptor == file.descriptor)
        #expect(reread.foregroundImages.count == file.foregroundImages.count)
        #expect(reread.backgroundImages.count == file.backgroundImages.count)
    }

    @Test("Foreground images are keyed by density directory name")
    func densityKeys() throws {
        let resDir = try makeTempResDir()
        defer { try? FileManager.default.removeItem(at: resDir) }
        try createSampleRes(
            at: resDir,
            densities: ["mipmap-mdpi", "mipmap-hdpi", "mipmap-xxxhdpi"]
        )

        let file = try AdaptiveIconFile(contentsOf: resDir)
        #expect(file.foregroundImages.keys.contains("mipmap-mdpi"))
        #expect(file.foregroundImages.keys.contains("mipmap-hdpi"))
        #expect(file.foregroundImages.keys.contains("mipmap-xxxhdpi"))
    }

    // MARK: - WebP support

    @Test("Read resolves WebP foreground images")
    func readWebP() throws {
        let resDir = try makeTempResDir()
        defer { try? FileManager.default.removeItem(at: resDir) }
        try createWebPRes(at: resDir)

        let file = try AdaptiveIconFile(contentsOf: resDir)
        #expect(file.foregroundImages.count == 2)
        #expect(file.foregroundExtensions["mipmap-hdpi"] == "webp")
        #expect(file.foregroundExtensions["mipmap-xxhdpi"] == "webp")
    }

    @Test("Write preserves WebP extension for unmodified files")
    func writeWebPRoundTrip() throws {
        let resDir = try makeTempResDir()
        let outputDir = try makeTempResDir()
        defer {
            try? FileManager.default.removeItem(at: resDir)
            try? FileManager.default.removeItem(at: outputDir)
        }
        try createWebPRes(at: resDir)

        let file = try AdaptiveIconFile(contentsOf: resDir)
        try file.write(to: outputDir)

        // Verify .webp files were written (extension preserved for unmodified files)
        let fm = FileManager.default
        #expect(fm.fileExists(
            atPath: outputDir.appendingPathComponent("mipmap-hdpi/ic_launcher_foreground.webp").path
        ))
        #expect(!fm.fileExists(
            atPath: outputDir.appendingPathComponent("mipmap-hdpi/ic_launcher_foreground.png").path
        ))
    }

    @Test("PNG prefers over WebP when both exist")
    func pngPrefersOverWebP() throws {
        let resDir = try makeTempResDir()
        defer { try? FileManager.default.removeItem(at: resDir) }

        // Create res with both .png and .webp files
        try createSampleRes(at: resDir, densities: ["mipmap-hdpi"])
        // Also write a .webp alongside the .png
        try makePNG(width: 162, height: 162).write(
            to: resDir.appendingPathComponent("mipmap-hdpi/ic_launcher_foreground.webp")
        )

        let file = try AdaptiveIconFile(contentsOf: resDir)
        // PNG should be preferred since it comes first in supportedExtensions
        #expect(file.foregroundExtensions["mipmap-hdpi"] == "png")
    }
}
