import ArgumentParser
import Foundation
import IconKit

struct InspectCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "inspect",
        abstract: "Examine the structure of an .icon bundle."
    )

    @Argument(help: "Path to the .icon bundle.")
    var path: String

    @Flag(name: .long, help: "Output raw icon.json as pretty-printed JSON.")
    var json: Bool = false

    func run() throws {
        let url = URL(fileURLWithPath: path)

        if json {
            let jsonURL = url.appendingPathComponent("icon.json")
            let data = try Data(contentsOf: jsonURL)
            let object = try JSONSerialization.jsonObject(with: data)
            let pretty = try JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            )
            print(String(data: pretty, encoding: .utf8)!)
        } else {
            let descriptor = try IconComposerDescriptorFile(contentsOf: url)
            print(descriptor.inspectSummary(bundleName: url.lastPathComponent))
        }
    }
}
