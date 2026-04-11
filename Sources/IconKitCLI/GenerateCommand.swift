import ArgumentParser

struct GenerateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate new icon bundles.",
        subcommands: [GenerateSFCommand.self]
    )
}
