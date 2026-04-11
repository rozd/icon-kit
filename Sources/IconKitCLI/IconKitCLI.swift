import ArgumentParser
import IconKit

@main
struct IconKitCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "iconkit",
        abstract: "A tool for working with Apple .icon bundles.",
        version: IconKit.version,
        subcommands: [TestCommand.self, RibbonCommand.self, InspectCommand.self, GenerateCommand.self]
    )
}
