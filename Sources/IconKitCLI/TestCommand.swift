import ArgumentParser
import Foundation
import IconKit

struct TestCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "test",
        abstract: "Read an .icon bundle and write it back out to verify round-trip fidelity."
    )

    @Option(name: .long, help: "Path to the input .icon bundle.")
    var input: String

    @Option(name: .long, help: "Path to the output .icon bundle.")
    var output: String

    func run() throws {
        let inputURL = URL(fileURLWithPath: input)
        let outputURL = URL(fileURLWithPath: output)

        let descriptor = try IconComposerDescriptorFile(contentsOf: inputURL)

        let missing = descriptor.validateAssets()
        if !missing.isEmpty {
            print("Warning: \(missing.count) referenced asset(s) not found in bundle:")
            for name in missing {
                print("  - \(name)")
            }
        }

        print("Read \(inputURL.lastPathComponent): \(descriptor.document.groups.count) group(s), \(descriptor.assets.count) asset(s)")

        try descriptor.write(to: outputURL)

        print("Wrote \(outputURL.lastPathComponent)")
    }
}
