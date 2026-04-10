import Testing
import Foundation
@testable import IconKit

@Suite("IconComposerDescriptorFile")
struct IconComposerDescriptorFileTests {

    private func makeTempDir() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("IconKitTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private var sampleDocument: IconDocument {
        IconDocument(
            colorSpaceForUntaggedSVGColors: "display-p3",
            fill: .automatic,
            groups: [
                IconGroup(
                    id: "group-1",
                    name: "Background",
                    layers: [
                        IconLayer(
                            id: "layer-1",
                            name: "BG",
                            imageName: "Background.png",
                            opacity: 1.0
                        ),
                    ],
                    shadow: .neutral,
                    lighting: .combined
                ),
                IconGroup(
                    id: "group-2",
                    name: "Foreground",
                    layers: [
                        IconLayer(
                            id: "layer-2",
                            imageName: "Foreground.svg",
                            blendMode: .multiply,
                            imageNameSpecializations: [
                                Specialization(appearance: .dark, value: "Foreground-Dark.svg"),
                            ]
                        ),
                    ]
                ),
            ],
            supportedPlatforms: SupportedPlatforms(circles: true, squares: .shared)
        )
    }

    // MARK: - Write and read

    @Test("Write and read bundle round-trips document")
    func writeAndRead() throws {
        let tempDir = try makeTempDir()
        defer { cleanup(tempDir) }
        let bundleURL = tempDir.appendingPathComponent("Test.icon")

        let assetData = Data("fake-png-data".utf8)
        var original = IconComposerDescriptorFile(document: sampleDocument)
        original.assets["Background.png"] = assetData
        original.assets["Foreground.svg"] = Data("<svg/>".utf8)

        try original.write(to: bundleURL)
        let loaded = try IconComposerDescriptorFile(contentsOf: bundleURL)

        #expect(loaded.document == original.document)
        #expect(loaded.assets["Background.png"] == assetData)
        #expect(loaded.assets["Foreground.svg"] == Data("<svg/>".utf8))
    }

    @Test("Written icon.json exists and is valid JSON")
    func writtenJsonIsValid() throws {
        let tempDir = try makeTempDir()
        defer { cleanup(tempDir) }
        let bundleURL = tempDir.appendingPathComponent("Test.icon")

        let file = IconComposerDescriptorFile(document: sampleDocument)
        try file.write(to: bundleURL)

        let jsonURL = bundleURL.appendingPathComponent("icon.json")
        let jsonData = try Data(contentsOf: jsonURL)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        #expect(json != nil)
        #expect(json?["groups"] != nil)
    }

    @Test("Write bundle with no assets skips Assets directory")
    func writeNoAssets() throws {
        let tempDir = try makeTempDir()
        defer { cleanup(tempDir) }
        let bundleURL = tempDir.appendingPathComponent("Test.icon")

        let file = IconComposerDescriptorFile(document: IconDocument(groups: []))
        try file.write(to: bundleURL)

        let assetsURL = bundleURL.appendingPathComponent("Assets")
        #expect(!FileManager.default.fileExists(atPath: assetsURL.path))
    }

    // MARK: - Read edge cases

    @Test("Read bundle with empty Assets directory")
    func readEmptyAssets() throws {
        let tempDir = try makeTempDir()
        defer { cleanup(tempDir) }
        let bundleURL = tempDir.appendingPathComponent("Test.icon")

        try FileManager.default.createDirectory(
            at: bundleURL.appendingPathComponent("Assets"),
            withIntermediateDirectories: true
        )
        let jsonData = try JSONEncoder().encode(IconDocument(groups: []))
        try jsonData.write(to: bundleURL.appendingPathComponent("icon.json"))

        let loaded = try IconComposerDescriptorFile(contentsOf: bundleURL)
        #expect(loaded.assets.isEmpty)
    }

    @Test("Read bundle without Assets directory succeeds")
    func readNoAssetsDir() throws {
        let tempDir = try makeTempDir()
        defer { cleanup(tempDir) }
        let bundleURL = tempDir.appendingPathComponent("Test.icon")

        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        let jsonData = try JSONEncoder().encode(IconDocument(groups: []))
        try jsonData.write(to: bundleURL.appendingPathComponent("icon.json"))

        let loaded = try IconComposerDescriptorFile(contentsOf: bundleURL)
        #expect(loaded.assets.isEmpty)
        #expect(loaded.document.groups.isEmpty)
    }

    @Test("Read missing icon.json throws")
    func readMissingJson() throws {
        let tempDir = try makeTempDir()
        defer { cleanup(tempDir) }
        let bundleURL = tempDir.appendingPathComponent("Test.icon")
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)

        #expect(throws: (any Error).self) {
            try IconComposerDescriptorFile(contentsOf: bundleURL)
        }
    }

    @Test("Read nonexistent bundle throws")
    func readNonexistent() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent-\(UUID().uuidString).icon")

        #expect(throws: (any Error).self) {
            try IconComposerDescriptorFile(contentsOf: url)
        }
    }

    // MARK: - Referenced image names

    @Test("referencedImageNames collects base and specialization names")
    func referencedImageNames() {
        let file = IconComposerDescriptorFile(document: sampleDocument)
        let names = file.referencedImageNames
        #expect(names.contains("Background.png"))
        #expect(names.contains("Foreground.svg"))
        #expect(names.contains("Foreground-Dark.svg"))
        #expect(names.count == 3)
    }

    @Test("referencedImageNames is empty for document with no layers")
    func referencedImageNamesEmpty() {
        let file = IconComposerDescriptorFile(document: IconDocument(groups: []))
        #expect(file.referencedImageNames.isEmpty)
    }

    // MARK: - Validate assets

    @Test("validateAssets reports missing assets")
    func validateAssetsMissing() {
        var file = IconComposerDescriptorFile(document: sampleDocument)
        file.assets["Background.png"] = Data()
        // Missing: Foreground.svg and Foreground-Dark.svg

        let missing = file.validateAssets()
        #expect(missing.contains("Foreground.svg"))
        #expect(missing.contains("Foreground-Dark.svg"))
        #expect(!missing.contains("Background.png"))
    }

    @Test("validateAssets returns empty when all assets present")
    func validateAssetsComplete() {
        var file = IconComposerDescriptorFile(document: sampleDocument)
        file.assets["Background.png"] = Data()
        file.assets["Foreground.svg"] = Data()
        file.assets["Foreground-Dark.svg"] = Data()

        #expect(file.validateAssets().isEmpty)
    }

    // MARK: - Equality

    @Test("Two identical descriptors are equal")
    func equality() {
        let a = IconComposerDescriptorFile(document: sampleDocument)
        let b = IconComposerDescriptorFile(document: sampleDocument)
        #expect(a == b)
    }

    @Test("Different documents are not equal")
    func inequality() {
        let a = IconComposerDescriptorFile(document: sampleDocument)
        let b = IconComposerDescriptorFile(document: IconDocument(groups: []))
        #expect(a != b)
    }
}
