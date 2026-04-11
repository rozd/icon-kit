import ArgumentParser
import Foundation
import IconKit

struct GenerateSFCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sf",
        abstract: "Generate an icon from an SF Symbol."
    )

    @Option(name: .long, help: "SF Symbol name (e.g. \"shippingbox.fill\").")
    var symbol: String

    @Option(name: .long, help: "Path to output .icon bundle.")
    var output: String

    @Option(name: .long, help: "Background color as hex (e.g. \"#4A90D9\").")
    var background: String = "#007AFF"

    @Option(name: .long, help: "Symbol color as hex (e.g. \"#FFFFFF\").")
    var foreground: String = "#FFFFFF"

    @Option(name: .long, help: "Symbol size as fraction of icon (0.0-1.0, where 1.0 fills the icon).")
    var size: Double = 0.6

    @Option(name: .long, help: "Horizontal offset as fraction of icon width.")
    var offsetX: Double = 0.0

    @Option(name: .long, help: "Vertical offset as fraction of icon height.")
    var offsetY: Double = 0.0

    func run() throws {
        let fgColor = try parseHexColor(foreground)
        let bgColor = try parseHexIconColor(background)

        let style = SFSymbolStyle(
            symbolName: symbol,
            foreground: fgColor,
            size: size,
            offsetX: offsetX,
            offsetY: offsetY
        )

        let outputURL = URL(fileURLWithPath: output)
        let descriptor = try IconComposerDescriptorFile.sfSymbol(
            style: style,
            background: bgColor
        )
        try descriptor.write(to: outputURL)

        print("Generated icon with SF Symbol '\(symbol)'")
        print("Wrote \(outputURL.lastPathComponent)")
    }
}
