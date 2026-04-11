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

    @Option(name: .long, help: "Path to input .icon bundle.")
    var input: String

    @Option(name: .long, help: "Path to output .icon bundle.")
    var output: String

    @Option(name: .long, help: "Ribbon size as factor of icon height (0.0-1.0).")
    var size: Double = 0.24

    @Option(name: .long, help: "Offset from edge as factor of icon height (0.0-1.0).")
    var offset: Double = 0.0

    @Option(name: .long, help: "Ribbon background color as hex (e.g. \"#FF0000\").")
    var background: String = "#000000"

    @Option(name: .long, help: "Text color as hex (e.g. \"#FFFFFF\").")
    var foreground: String = "#FFFFFF"

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

        var descriptor = try IconComposerDescriptorFile(contentsOf: inputURL)

        try descriptor.applyRibbon(placement: placement, style: style)
        try descriptor.write(to: outputURL)

        print("Added '\(text)' ribbon (\(placement.rawValue)) as overlay layer")
        print("Wrote \(outputURL.lastPathComponent)")
    }
}
