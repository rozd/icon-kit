import ArgumentParser
import Foundation
import IconKit

extension RibbonPlacement: ExpressibleByArgument {}

struct RibbonCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ribbon",
        abstract: "Add a text ribbon overlay to icon assets."
    )

    @Argument(help: "Ribbon placement: top, bottom, topLeft, topRight.")
    var placement: RibbonPlacement

    @Option(name: .long, help: "Text to render on the ribbon.")
    var text: String

    @Option(name: .long, help: "Path to input icon (.icon bundle, adaptive icon XML, or Android res/ directory).")
    var input: String

    @Option(name: .long, help: "Path to output location.")
    var output: String

    @Option(name: .long, help: "Ribbon size as factor of icon height (0.0-1.0).")
    var size: Double = 0.24

    @Option(name: .long, help: "Offset from edge as factor of icon height (0.0-1.0).")
    var offset: Double = 0.0

    @Option(name: .long, help: "Ribbon background color as hex (e.g. \"#FF0000\").")
    var background: String = "#B92636"

    @Option(name: .long, help: "Text color as hex (e.g. \"#FFFFFF\").")
    var foreground: String = "#FEFAFA"

    @Option(name: .long, help: "Font family name.")
    var font: String?

    @Option(name: .long, help: "Text size as factor of ribbon height (0.0-1.0).")
    var fontScale: Double = 0.6

    func run() throws {
        let bgColor = try parseHexColor(background)
        let fgColor = try parseHexColor(foreground)

        let style = RibbonStyle(
            text: text,
            size: size,
            offset: offset,
            background: bgColor,
            foreground: fgColor,
            fontName: font,
            fontScale: fontScale
        )

        let inputURL = URL(fileURLWithPath: input)
        let outputURL = URL(fileURLWithPath: output)

        switch detectFormat(inputURL) {
        case .iconComposer:
            var descriptor = try IconComposerDescriptorFile(contentsOf: inputURL)
            try descriptor.applyRibbon(placement: placement, style: style)
            try descriptor.write(to: outputURL)
            print("Added '\(text)' ribbon (\(placement.rawValue)) as overlay layer")
            print("Wrote \(outputURL.lastPathComponent)")

        case .androidAdaptive:
            var adaptive = try AdaptiveIconFile(contentsOf: inputURL)
            try adaptive.applyRibbon(placement: placement, style: style)
            try adaptive.write(to: outputURL)
            print("Added '\(text)' ribbon (\(placement.rawValue)) to adaptive icon foreground")
            print("Wrote to \(outputURL.path)")
        }
    }
}

// MARK: - Format Detection

private enum IconFormat {
    case iconComposer
    case androidAdaptive
}

private func detectFormat(_ url: URL) -> IconFormat {
    let fm = FileManager.default

    // .icon bundle: ends with .icon or contains icon.json
    if url.pathExtension == "icon" {
        return .iconComposer
    }
    if fm.fileExists(atPath: url.appendingPathComponent("icon.json").path) {
        return .iconComposer
    }

    // Android adaptive icon: XML file
    if url.pathExtension == "xml" {
        return .androidAdaptive
    }

    // Android res/ directory: contains mipmap-anydpi-v26/
    if fm.fileExists(atPath: url.appendingPathComponent("mipmap-anydpi-v26").path) {
        return .androidAdaptive
    }

    // Default to .icon for backwards compatibility
    return .iconComposer
}
