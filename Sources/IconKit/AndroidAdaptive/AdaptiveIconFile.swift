import Foundation

/// Facade for reading and writing Android adaptive icon resources.
///
/// An adaptive icon is described by an XML file (typically `ic_launcher.xml`)
/// inside `res/mipmap-anydpi-v26/` that references drawable or mipmap image assets
/// (PNG or WebP) at various screen densities.
///
/// ## Reading
///
/// The initializer accepts either:
/// - A direct path to the adaptive icon XML file
/// - A path to the Android `res/` directory (auto-discovers XML in `mipmap-anydpi-v26/`)
///
/// Referenced foreground and background images (PNG or WebP) are resolved from
/// sibling density-qualified directories (e.g. `mipmap-mdpi/`, `mipmap-xxxhdpi/`).
///
/// ## Writing
///
/// Only modified foreground images are written. The XML descriptor and
/// background images are preserved as-is.
public struct AdaptiveIconFile: Sendable {

    /// The parsed adaptive icon descriptor.
    public var descriptor: AdaptiveIcon

    /// The original XML data (preserved for round-trip fidelity).
    public var xmlData: Data

    /// Path to the XML file within the res/ directory.
    public var xmlRelativePath: String

    /// The res/ directory URL.
    public var resDirectory: URL

    /// Foreground images keyed by density-qualified directory name
    /// (e.g. `"mipmap-xxxhdpi"` → image data).
    public var foregroundImages: [String: Data]

    /// Background images keyed by density-qualified directory name.
    public var backgroundImages: [String: Data]

    /// File extensions for foreground images keyed by density directory name
    /// (e.g. `"mipmap-xxxhdpi"` → `"webp"`). Defaults to `"png"` when not set.
    public var foregroundExtensions: [String: String]

    /// File extensions for background images keyed by density directory name.
    public var backgroundExtensions: [String: String]

    public init(
        descriptor: AdaptiveIcon,
        xmlData: Data,
        xmlRelativePath: String,
        resDirectory: URL,
        foregroundImages: [String: Data],
        backgroundImages: [String: Data],
        foregroundExtensions: [String: String] = [:],
        backgroundExtensions: [String: String] = [:]
    ) {
        self.descriptor = descriptor
        self.xmlData = xmlData
        self.xmlRelativePath = xmlRelativePath
        self.resDirectory = resDirectory
        self.foregroundImages = foregroundImages
        self.backgroundImages = backgroundImages
        self.foregroundExtensions = foregroundExtensions
        self.backgroundExtensions = backgroundExtensions
    }

    /// Read an adaptive icon from its XML descriptor or a res/ directory.
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

        if isDir.boolValue {
            // Input is a directory — try to find XML in mipmap-anydpi-v26/
            resDir = url
            guard let found = try Self.discoverXML(in: resDir) else {
                throw AdaptiveIconError.xmlNotFound(url.appendingPathComponent("mipmap-anydpi-v26"))
            }
            xmlURL = found
        } else {
            // Input is an XML file path
            xmlURL = url
            // res/ is the grandparent: res/mipmap-anydpi-v26/ic_launcher.xml
            resDir = xmlURL.deletingLastPathComponent().deletingLastPathComponent()
        }

        guard fm.fileExists(atPath: resDir.path) else {
            throw AdaptiveIconError.resDirectoryNotFound(resDir)
        }

        let data = try Data(contentsOf: xmlURL)
        let icon = try AdaptiveIcon(xmlData: data)

        self.descriptor = icon
        self.xmlData = data
        let resComponents = resDir.standardizedFileURL.pathComponents
        let xmlComponents = xmlURL.standardizedFileURL.pathComponents
        self.xmlRelativePath = xmlComponents.dropFirst(resComponents.count)
            .joined(separator: "/")
        self.resDirectory = resDir

        // Resolve referenced images
        self.foregroundImages = [:]
        self.backgroundImages = [:]
        self.foregroundExtensions = [:]
        self.backgroundExtensions = [:]

        if let ref = icon.foreground {
            let resolved = try Self.resolveImages(drawableRef: ref, in: resDir)
            self.foregroundImages = resolved.images
            self.foregroundExtensions = resolved.extensions
        }
        if let ref = icon.background {
            if let resolved = try? Self.resolveImages(drawableRef: ref, in: resDir) {
                self.backgroundImages = resolved.images
                self.backgroundExtensions = resolved.extensions
            }
        }
    }

    /// Write the adaptive icon to a res/ directory.
    ///
    /// Writes the XML descriptor and all foreground images.
    /// Background images are only written if the output differs from the input.
    public func write(to resDir: URL) throws {
        let fm = FileManager.default

        // Write XML descriptor
        let xmlDir = resDir.appendingPathComponent(
            (xmlRelativePath as NSString).deletingLastPathComponent
        )
        try fm.createDirectory(at: xmlDir, withIntermediateDirectories: true)
        try xmlData.write(to: resDir.appendingPathComponent(xmlRelativePath))

        // Write foreground images
        if let ref = descriptor.foreground,
           let parsed = AdaptiveIcon.parseDrawableReference(ref) {
            for (dirName, data) in foregroundImages {
                let dir = resDir.appendingPathComponent(dirName)
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                let ext = foregroundExtensions[dirName] ?? "png"
                let file = dir.appendingPathComponent("\(parsed.name).\(ext)")
                try data.write(to: file)
            }
        }

        // Write background images
        if let ref = descriptor.background,
           let parsed = AdaptiveIcon.parseDrawableReference(ref) {
            for (dirName, data) in backgroundImages {
                let dir = resDir.appendingPathComponent(dirName)
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                let ext = backgroundExtensions[dirName] ?? "png"
                let file = dir.appendingPathComponent("\(parsed.name).\(ext)")
                try data.write(to: file)
            }
        }
    }

    // MARK: - Private

    /// Discover an adaptive icon XML file in a res/ directory.
    private static func discoverXML(in resDir: URL) throws -> URL? {
        let anydpiDir = resDir.appendingPathComponent("mipmap-anydpi-v26")
        let fm = FileManager.default

        guard fm.fileExists(atPath: anydpiDir.path) else { return nil }

        let contents = try fm.contentsOfDirectory(
            at: anydpiDir, includingPropertiesForKeys: nil
        )
        // Prefer ic_launcher.xml, otherwise take the first .xml file
        if let launcher = contents.first(where: { $0.lastPathComponent == "ic_launcher.xml" }) {
            return launcher
        }
        return contents.first(where: { $0.pathExtension == "xml" })
    }

    /// Supported image file extensions, in priority order.
    private static let supportedExtensions = ["png", "webp"]

    /// Resolved images with their file extensions.
    private struct ResolvedImages {
        var images: [String: Data]
        var extensions: [String: String]
    }

    /// Resolve a drawable reference to image files across density directories.
    /// Supports both PNG and WebP formats.
    private static func resolveImages(
        drawableRef: String,
        in resDir: URL
    ) throws -> ResolvedImages {
        guard let parsed = AdaptiveIcon.parseDrawableReference(drawableRef) else {
            throw AdaptiveIconError.cannotResolveDrawable(drawableRef)
        }

        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(
            at: resDir, includingPropertiesForKeys: [.isDirectoryKey]
        )

        var images: [String: Data] = [:]
        var extensions: [String: String] = [:]

        for dir in contents {
            let dirName = dir.lastPathComponent
            // Match directories starting with the reference type
            // e.g. "mipmap-mdpi", "mipmap-hdpi", "drawable-xhdpi", or just "drawable"
            guard dirName == parsed.type || dirName.hasPrefix("\(parsed.type)-") else {
                continue
            }
            // Skip the anydpi directory (it contains XML, not images)
            guard !dirName.contains("anydpi") else { continue }

            for ext in supportedExtensions {
                let file = dir.appendingPathComponent("\(parsed.name).\(ext)")
                if fm.fileExists(atPath: file.path) {
                    images[dirName] = try Data(contentsOf: file)
                    extensions[dirName] = ext
                    break
                }
            }
        }

        return ResolvedImages(images: images, extensions: extensions)
    }
}
