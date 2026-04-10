import Foundation

/// Facade for reading and writing Apple Icon Composer `.icon` bundles.
///
/// An `.icon` bundle is a directory containing:
/// - `icon.json` — the document descriptor
/// - `Assets/` — referenced image files (SVG, PNG)
///
/// Usage:
/// ```swift
/// // Read an existing bundle
/// let icon = try IconComposerDescriptorFile(contentsOf: bundleURL)
/// print(icon.document.groups.count)
///
/// // Create and write a new bundle
/// var icon = IconComposerDescriptorFile(document: myDocument)
/// icon.assets["Background.svg"] = svgData
/// try icon.write(to: outputURL)
/// ```
public struct IconComposerDescriptorFile: Hashable, Sendable {

    /// The parsed document model from `icon.json`.
    public var document: IconDocument

    /// Asset data keyed by filename (files from the `Assets/` directory).
    public var assets: [String: Data]

    // MARK: - Initialization

    public init(document: IconDocument, assets: [String: Data] = [:]) {
        self.document = document
        self.assets = assets
    }

    // MARK: - Reading

    /// Read an `.icon` bundle from the given directory URL.
    ///
    /// - Parameter bundleURL: Path to the `.icon` bundle directory.
    /// - Throws: If `icon.json` cannot be read or decoded.
    public init(contentsOf bundleURL: URL) throws {
        let jsonURL = bundleURL.appendingPathComponent("icon.json")
        let jsonData = try Data(contentsOf: jsonURL)
        self.document = try JSONDecoder().decode(IconDocument.self, from: jsonData)

        let assetsURL = bundleURL.appendingPathComponent("Assets")
        var loadedAssets: [String: Data] = [:]
        let fm = FileManager.default
        if fm.fileExists(atPath: assetsURL.path) {
            let contents = try fm.contentsOfDirectory(
                at: assetsURL,
                includingPropertiesForKeys: nil
            )
            for fileURL in contents {
                let data = try Data(contentsOf: fileURL)
                loadedAssets[fileURL.lastPathComponent] = data
            }
        }
        self.assets = loadedAssets
    }

    // MARK: - Writing

    /// Write the `.icon` bundle to the given directory URL.
    ///
    /// Creates the bundle directory, writes `icon.json`, and writes all assets
    /// to the `Assets/` subdirectory.
    ///
    /// - Parameter bundleURL: Path where the `.icon` bundle should be written.
    /// - Throws: If the directory cannot be created or files cannot be written.
    public func write(to bundleURL: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: bundleURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let jsonData = try encoder.encode(document)
        let jsonURL = bundleURL.appendingPathComponent("icon.json")
        try jsonData.write(to: jsonURL)

        if !assets.isEmpty {
            let assetsURL = bundleURL.appendingPathComponent("Assets")
            try fm.createDirectory(at: assetsURL, withIntermediateDirectories: true)
            for (name, data) in assets {
                let fileURL = assetsURL.appendingPathComponent(name)
                try data.write(to: fileURL)
            }
        }
    }

    // MARK: - Convenience

    /// All image filenames referenced by layers in the document,
    /// including those in specializations.
    public var referencedImageNames: Set<String> {
        var names = Set<String>()
        for group in document.groups {
            for layer in group.layers {
                if let imageName = layer.imageName {
                    names.insert(imageName)
                }
                if let specs = layer.imageNameSpecializations {
                    for spec in specs {
                        names.insert(spec.value)
                    }
                }
            }
        }
        return names
    }

    /// Returns asset filenames that are referenced in the document but missing from `assets`.
    ///
    /// An empty array means all referenced assets are present.
    public func validateAssets() -> [String] {
        let available = Set(assets.keys)
        return referencedImageNames.subtracting(available).sorted()
    }
}
