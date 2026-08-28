import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Represents an Android adaptive icon resource hierarchy inside a `res/` directory.
///
/// ## Adaptive Icon Structure
///
/// An adaptive icon XML descriptor (typically at `res/mipmap-anydpi-v26/ic_launcher.xml`
/// and `ic_launcher_round.xml`) references a foreground and background layer:
///
/// ```xml
/// <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
///     <background android:drawable="@color/ic_launcher_background" />
///     <foreground android:drawable="@drawable/ic_launcher_foreground" />
/// </adaptive-icon>
/// ```
///
/// ## Modern Vector Drawables
///
/// In modern Android projects, `@drawable/ic_launcher_foreground` refers to an Android
/// Vector Drawable XML (`res/drawable/ic_launcher_foreground.xml`) containing `<vector>`.
///
/// When a Vector Drawable foreground is detected, IconKit renders it at all standard
/// Android adaptive icon densities (mdpi: 108px, hdpi: 162px, xhdpi: 216px, xxhdpi: 324px, xxxhdpi: 432px).
///
/// ## Writing
///
/// Modified foreground images and legacy launcher icons are written to their respective
/// density directories. When replacing a Vector Drawable with rasterized density assets,
/// the vector XML in the target directory is cleaned up to ensure Android build tools (AAPT2)
/// cleanly pick the newly rendered density assets.
public struct AdaptiveIconFile: Sendable {

    /// Standard Android densities for adaptive icons (108dp) and legacy launcher icons (48dp).
    public static let standardDensities: [(suffix: String, scale: Double, adaptiveSize: Int, legacySize: Int)] = [
        ("mdpi", 1.0, 108, 48),
        ("hdpi", 1.5, 162, 72),
        ("xhdpi", 2.0, 216, 96),
        ("xxhdpi", 3.0, 324, 144),
        ("xxxhdpi", 4.0, 432, 192),
    ]

    /// Supported image file extensions, in priority order.
    private static let supportedExtensions = ["png", "webp"]

    /// Potential anydpi directory names containing adaptive icon XMLs.
    private static let anydpiDirNames = [
        "mipmap-anydpi-v26",
        "mipmap-anydpi",
        "drawable-anydpi-v26",
        "drawable-anydpi",
    ]

    /// Potential drawable directory names for vector drawables.
    private static let drawableDirNames = [
        "drawable",
        "drawable-v24",
        "drawable-v21",
        "drawable-anydpi-v26",
        "drawable-anydpi",
    ]

    /// The parsed primary adaptive icon descriptor.
    public var descriptor: AdaptiveIcon

    /// The original XML data (preserved for round-trip fidelity).
    public var xmlData: Data

    /// Path to the primary XML file within the res/ directory.
    public var xmlRelativePath: String

    /// Additional adaptive icon XML files (e.g. `ic_launcher_round.xml`) relative path -> data.
    public var additionalXMLFiles: [String: Data]

    /// The res/ directory URL.
    public var resDirectory: URL

    /// Foreground images keyed by density-qualified directory name
    /// (e.g. `"drawable-xxxhdpi"` or `"mipmap-xxxhdpi"` → image data).
    public var foregroundImages: [String: Data]

    /// Background images keyed by density-qualified directory name.
    public var backgroundImages: [String: Data]

    /// File extensions for foreground images keyed by density directory name
    /// (e.g. `"mipmap-xxxhdpi"` → `"webp"`). Defaults to `"png"` when not set.
    public var foregroundExtensions: [String: String]

    /// File extensions for background images keyed by density directory name.
    public var backgroundExtensions: [String: String]

    /// Whether the foreground layer was loaded from a Vector Drawable XML.
    public var isForegroundVector: Bool

    /// Whether the background layer was loaded from a Vector Drawable XML.
    public var isBackgroundVector: Bool

    /// Relative paths to Vector Drawable XML files that were rasterized.
    public var vectorRelativePaths: [String]

    /// Legacy launcher icons keyed by icon name and density directory name
    /// (e.g. `"ic_launcher"` → `["mipmap-xxhdpi": data, ...]` and `"ic_launcher_round"` → `[...]`).
    public var legacyIcons: [String: [String: Data]]

    /// File extensions for legacy launcher icons.
    public var legacyExtensions: [String: [String: String]]

    public init(
        descriptor: AdaptiveIcon,
        xmlData: Data,
        xmlRelativePath: String,
        resDirectory: URL,
        foregroundImages: [String: Data],
        backgroundImages: [String: Data],
        foregroundExtensions: [String: String] = [:],
        backgroundExtensions: [String: String] = [:],
        isForegroundVector: Bool = false,
        isBackgroundVector: Bool = false,
        vectorRelativePaths: [String] = [],
        additionalXMLFiles: [String: Data] = [:],
        legacyIcons: [String: [String: Data]] = [:],
        legacyExtensions: [String: [String: String]] = [:]
    ) {
        self.descriptor = descriptor
        self.xmlData = xmlData
        self.xmlRelativePath = xmlRelativePath
        self.resDirectory = resDirectory
        self.foregroundImages = foregroundImages
        self.backgroundImages = backgroundImages
        self.foregroundExtensions = foregroundExtensions
        self.backgroundExtensions = backgroundExtensions
        self.isForegroundVector = isForegroundVector
        self.isBackgroundVector = isBackgroundVector
        self.vectorRelativePaths = vectorRelativePaths
        self.additionalXMLFiles = additionalXMLFiles
        self.legacyIcons = legacyIcons
        self.legacyExtensions = legacyExtensions
    }

    /// Read an adaptive icon from its XML descriptor or an Android `res/` directory.
    ///
    /// - Parameter url: Path to the adaptive icon XML file, or the `res/` directory.
    public init(contentsOf url: URL) throws {
        let fm = FileManager.default
        var isDir: ObjCBool = false

        guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else {
            if url.pathExtension == "xml" {
                throw AdaptiveIconError.xmlNotFound(url)
            }
            throw AdaptiveIconError.resDirectoryNotFound(url)
        }

        let xmlURL: URL
        let resDir: URL
        var discoveredXMLs: [URL] = []

        if isDir.boolValue {
            // Input is a directory — find all XMLs in anydpi directories
            resDir = url
            discoveredXMLs = try Self.discoverAllXMLs(in: resDir)
            guard let primary = discoveredXMLs.first else {
                throw AdaptiveIconError.xmlNotFound(url.appendingPathComponent("mipmap-anydpi-v26"))
            }
            xmlURL = primary
        } else {
            // Input is an XML file path
            xmlURL = url
            // res/ is the grandparent: res/mipmap-anydpi-v26/ic_launcher.xml
            resDir = xmlURL.deletingLastPathComponent().deletingLastPathComponent()
            discoveredXMLs = [xmlURL]
        }

        guard fm.fileExists(atPath: resDir.path) else {
            throw AdaptiveIconError.resDirectoryNotFound(resDir)
        }

        let primaryData = try Data(contentsOf: xmlURL)
        let primaryIcon = try AdaptiveIcon(xmlData: primaryData)

        self.descriptor = primaryIcon
        self.xmlData = primaryData
        let resComponents = resDir.standardizedFileURL.pathComponents
        let xmlComponents = xmlURL.standardizedFileURL.pathComponents
        self.xmlRelativePath = xmlComponents.dropFirst(resComponents.count).joined(separator: "/")
        self.resDirectory = resDir

        // Load additional XML files (e.g. ic_launcher_round.xml)
        var additionalXMLs: [String: Data] = [:]
        for otherURL in discoveredXMLs where otherURL != xmlURL {
            let otherComponents = otherURL.standardizedFileURL.pathComponents
            let rel = otherComponents.dropFirst(resComponents.count).joined(separator: "/")
            if let data = try? Data(contentsOf: otherURL) {
                additionalXMLs[rel] = data
            }
        }
        self.additionalXMLFiles = additionalXMLs

        // Load colors for color resolution
        let colors = AndroidColor.loadColors(from: resDir)
        let colorResolver: @Sendable (String) -> CGColor? = { name in
            colors[name]
        }

        // Resolve referenced images
        self.foregroundImages = [:]
        self.backgroundImages = [:]
        self.foregroundExtensions = [:]
        self.backgroundExtensions = [:]
        self.isForegroundVector = false
        self.isBackgroundVector = false
        self.vectorRelativePaths = []
        self.legacyIcons = [:]
        self.legacyExtensions = [:]

        // 1. Resolve Foreground
        if let ref = primaryIcon.foreground {
            let resolved = try Self.resolveForeground(
                drawableRef: ref,
                in: resDir,
                colorResolver: colorResolver
            )
            self.foregroundImages = resolved.images
            self.foregroundExtensions = resolved.extensions
            self.isForegroundVector = resolved.isVector
            self.vectorRelativePaths = resolved.vectorRelativePaths
        }

        // 2. Resolve Background
        if let ref = primaryIcon.background {
            if let resolved = try? Self.resolveBackground(
                drawableRef: ref,
                in: resDir,
                colorResolver: colorResolver
            ) {
                self.backgroundImages = resolved.images
                self.backgroundExtensions = resolved.extensions
                self.isBackgroundVector = resolved.isVector
            }
        }

        // 3. Resolve Legacy Launcher Icons (ic_launcher, ic_launcher_round, etc.)
        let legacyNames = Self.collectLegacyIconNames(from: discoveredXMLs)
        for name in legacyNames {
            let resolved = try? Self.resolveLegacyIcons(name: name, in: resDir)
            if let resolved, !resolved.images.isEmpty {
                self.legacyIcons[name] = resolved.images
                self.legacyExtensions[name] = resolved.extensions
            }
        }
    }

    /// Write the adaptive icon resources to a `res/` directory.
    public func write(to resDir: URL) throws {
        let fm = FileManager.default

        // 1. Write Primary XML descriptor
        let xmlDir = resDir.appendingPathComponent(
            (xmlRelativePath as NSString).deletingLastPathComponent
        )
        try fm.createDirectory(at: xmlDir, withIntermediateDirectories: true)
        try xmlData.write(to: resDir.appendingPathComponent(xmlRelativePath))

        // 2. Write Additional XML descriptors
        for (relPath, data) in additionalXMLFiles {
            let dir = resDir.appendingPathComponent((relPath as NSString).deletingLastPathComponent)
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            try data.write(to: resDir.appendingPathComponent(relPath))
        }

        // 3. Write Foreground images
        if let ref = descriptor.foreground,
           let parsed = AdaptiveIcon.parseDrawableReference(ref) {
            for (dirName, data) in foregroundImages {
                let dir = resDir.appendingPathComponent(dirName)
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                let ext = foregroundExtensions[dirName] ?? "png"
                let file = dir.appendingPathComponent("\(parsed.name).\(ext)")
                try data.write(to: file)

                // Clean up alternative extension if we switched to PNG
                if ext == "png" {
                    let oldWebP = dir.appendingPathComponent("\(parsed.name).webp")
                    if fm.fileExists(atPath: oldWebP.path) && oldWebP.path != file.path {
                        try? fm.removeItem(at: oldWebP)
                    }
                }
            }
        }

        // 4. Clean up original Vector XMLs if foreground was converted to density PNGs
        if isForegroundVector {
            for relPath in vectorRelativePaths {
                let vectorFile = resDir.appendingPathComponent(relPath)
                if fm.fileExists(atPath: vectorFile.path) {
                    try? fm.removeItem(at: vectorFile)
                }
            }
        }

        // 5. Write Background images ONLY IF background is bitmap assets (not vector or color)
        if let ref = descriptor.background,
           let parsed = AdaptiveIcon.parseDrawableReference(ref),
           !backgroundImages.isEmpty,
           !isBackgroundVector {
            for (dirName, data) in backgroundImages {
                let dir = resDir.appendingPathComponent(dirName)
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                let ext = backgroundExtensions[dirName] ?? "png"
                let file = dir.appendingPathComponent("\(parsed.name).\(ext)")
                try data.write(to: file)
            }
        }

        // 6. Write Legacy Launcher Icons
        for (iconName, densityMap) in legacyIcons {
            for (dirName, data) in densityMap {
                let dir = resDir.appendingPathComponent(dirName)
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                let ext = legacyExtensions[iconName]?[dirName] ?? "png"
                let file = dir.appendingPathComponent("\(iconName).\(ext)")
                try data.write(to: file)

                // Clean up alternative extension if we switched to PNG
                if ext == "png" {
                    let oldWebP = dir.appendingPathComponent("\(iconName).webp")
                    if fm.fileExists(atPath: oldWebP.path) && oldWebP.path != file.path {
                        try? fm.removeItem(at: oldWebP)
                    }
                }
            }
        }
    }

    // MARK: - Discovery Helpers

    /// Discover all adaptive icon XML files in a res/ directory.
    private static func discoverAllXMLs(in resDir: URL) throws -> [URL] {
        let fm = FileManager.default
        var results: [URL] = []

        for anydpiName in anydpiDirNames {
            let dir = resDir.appendingPathComponent(anydpiName)
            guard fm.fileExists(atPath: dir.path) else { continue }

            let contents = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            let xmls = contents.filter { $0.pathExtension == "xml" }
            results.append(contentsOf: xmls)
        }

        // Sort so that ic_launcher.xml comes first, followed by ic_launcher_round.xml, then others
        results.sort { a, b in
            let aName = a.lastPathComponent
            let bName = b.lastPathComponent
            if aName == "ic_launcher.xml" { return true }
            if bName == "ic_launcher.xml" { return false }
            if aName == "ic_launcher_round.xml" { return true }
            if bName == "ic_launcher_round.xml" { return false }
            return aName < bName
        }

        return results
    }

    /// Collect icon base names to search for legacy launcher bitmaps.
    private static func collectLegacyIconNames(from xmlURLs: [URL]) -> [String] {
        var names: [String] = []
        for url in xmlURLs {
            let baseName = url.deletingPathExtension().lastPathComponent
            if !names.contains(baseName) {
                names.append(baseName)
            }
        }
        if names.isEmpty {
            names = ["ic_launcher", "ic_launcher_round"]
        }
        return names
    }

    // MARK: - Resolution Helpers

    private static func resolveForeground(
        drawableRef: String,
        in resDir: URL,
        colorResolver: (@Sendable (String) -> CGColor?)?
    ) throws -> (
        images: [String: Data],
        extensions: [String: String],
        isVector: Bool,
        vectorRelativePaths: [String]
    ) {
        guard let parsed = AdaptiveIcon.parseDrawableReference(drawableRef) else {
            throw AdaptiveIconError.cannotResolveDrawable(drawableRef)
        }

        // 1. Check for bitmap assets (PNG/WebP) across density folders
        let bitmapResolved = try resolveBitmapImages(type: parsed.type, name: parsed.name, in: resDir)
        if !bitmapResolved.images.isEmpty {
            return (
                images: bitmapResolved.images,
                extensions: bitmapResolved.extensions,
                isVector: false,
                vectorRelativePaths: []
            )
        }

        // 2. Check for Vector Drawable XML in drawable/ or drawable-*/ folders
        if let vectorFile = findVectorDrawableXML(type: parsed.type, name: parsed.name, in: resDir) {
            let xmlData = try Data(contentsOf: vectorFile)
            let vector = try VectorDrawable(xmlData: xmlData)
            let renderer = VectorDrawableRenderer(vector: vector, colorResolver: colorResolver)

            var images: [String: Data] = [:]
            var extensions: [String: String] = [:]

            let folderPrefix = parsed.type // e.g. "drawable" or "mipmap"
            for density in standardDensities {
                let dirName = "\(folderPrefix)-\(density.suffix)"
                let pngData = try renderer.renderPNG(
                    width: density.adaptiveSize,
                    height: density.adaptiveSize
                )
                images[dirName] = pngData
                extensions[dirName] = "png"
            }

            let resComponents = resDir.standardizedFileURL.pathComponents
            let vectorComponents = vectorFile.standardizedFileURL.pathComponents
            let relPath = vectorComponents.dropFirst(resComponents.count).joined(separator: "/")

            return (
                images: images,
                extensions: extensions,
                isVector: true,
                vectorRelativePaths: [relPath]
            )
        }

        throw AdaptiveIconError.cannotResolveDrawable(
            "\(drawableRef) (no vector XML in drawable/ or bitmap assets in density folders found)"
        )
    }

    private static func resolveBackground(
        drawableRef: String,
        in resDir: URL,
        colorResolver: (@Sendable (String) -> CGColor?)?
    ) throws -> (images: [String: Data], extensions: [String: String], isVector: Bool) {
        guard let parsed = AdaptiveIcon.parseDrawableReference(drawableRef) else {
            return ([:], [:], false)
        }

        // Try resolving bitmap images
        let bitmapResolved = try resolveBitmapImages(type: parsed.type, name: parsed.name, in: resDir)
        if !bitmapResolved.images.isEmpty {
            return (bitmapResolved.images, bitmapResolved.extensions, false)
        }

        // Try resolving vector XML
        if let vectorFile = findVectorDrawableXML(type: parsed.type, name: parsed.name, in: resDir) {
            let xmlData = try Data(contentsOf: vectorFile)
            if let vector = try? VectorDrawable(xmlData: xmlData) {
                let renderer = VectorDrawableRenderer(vector: vector, colorResolver: colorResolver)
                var images: [String: Data] = [:]
                var extensions: [String: String] = [:]
                let folderPrefix = parsed.type
                for density in standardDensities {
                    let dirName = "\(folderPrefix)-\(density.suffix)"
                    if let pngData = try? renderer.renderPNG(
                        width: density.adaptiveSize,
                        height: density.adaptiveSize
                    ) {
                        images[dirName] = pngData
                        extensions[dirName] = "png"
                    }
                }
                return (images, extensions, true)
            }
        }

        return ([:], [:], false)
    }

    private static func resolveLegacyIcons(
        name: String,
        in resDir: URL
    ) throws -> (images: [String: Data], extensions: [String: String]) {
        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(
            at: resDir, includingPropertiesForKeys: [.isDirectoryKey]
        )

        var images: [String: Data] = [:]
        var extensions: [String: String] = [:]

        for dir in contents {
            let dirName = dir.lastPathComponent
            guard dirName.hasPrefix("mipmap-") || dirName.hasPrefix("drawable-") else { continue }
            guard !dirName.contains("anydpi") else { continue }

            for ext in supportedExtensions {
                let file = dir.appendingPathComponent("\(name).\(ext)")
                if fm.fileExists(atPath: file.path) {
                    images[dirName] = try Data(contentsOf: file)
                    extensions[dirName] = ext
                    break
                }
            }
        }

        return (images, extensions)
    }

    private static func resolveBitmapImages(
        type: String,
        name: String,
        in resDir: URL
    ) throws -> (images: [String: Data], extensions: [String: String]) {
        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(
            at: resDir, includingPropertiesForKeys: [.isDirectoryKey]
        )

        var images: [String: Data] = [:]
        var extensions: [String: String] = [:]

        for dir in contents {
            let dirName = dir.lastPathComponent
            guard dirName == type || dirName.hasPrefix("\(type)-") else { continue }
            guard !dirName.contains("anydpi") else { continue }

            for ext in supportedExtensions {
                let file = dir.appendingPathComponent("\(name).\(ext)")
                if fm.fileExists(atPath: file.path) {
                    images[dirName] = try Data(contentsOf: file)
                    extensions[dirName] = ext
                    break
                }
            }
        }

        return (images, extensions)
    }

    private static func findVectorDrawableXML(type: String, name: String, in resDir: URL) -> URL? {
        let fm = FileManager.default

        // Check specific candidate directories
        var candidateDirs = drawableDirNames
        if type != "drawable" {
            candidateDirs.insert(type, at: 0)
        }

        for dirName in candidateDirs {
            let file = resDir.appendingPathComponent("\(dirName)/\(name).xml")
            if fm.fileExists(atPath: file.path) {
                return file
            }
        }

        // Also check any directory starting with type
        if let contents = try? fm.contentsOfDirectory(at: resDir, includingPropertiesForKeys: nil) {
            for dir in contents {
                let dirName = dir.lastPathComponent
                if dirName == type || dirName.hasPrefix("\(type)-") {
                    let file = dir.appendingPathComponent("\(name).xml")
                    if fm.fileExists(atPath: file.path) {
                        return file
                    }
                }
            }
        }

        return nil
    }
}
