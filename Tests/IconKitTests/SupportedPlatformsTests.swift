import Testing
import Foundation
@testable import IconKit

@Suite("SupportedPlatforms")
struct SupportedPlatformsTests {

    @Test("Decode shared squares with circles")
    func decodeSharedWithCircles() throws {
        let json = Data(#"{"circles":true,"squares":"shared"}"#.utf8)
        let platforms = try JSONDecoder().decode(SupportedPlatforms.self, from: json)
        #expect(platforms.circles == true)
        #expect(platforms.squares == .shared)
    }

    @Test("Decode platforms array for squares")
    func decodePlatformsArray() throws {
        let json = Data(#"{"squares":{"platforms":["iOS","macOS","visionOS"]}}"#.utf8)
        let platforms = try JSONDecoder().decode(SupportedPlatforms.self, from: json)
        #expect(platforms.circles == nil)
        #expect(platforms.squares == .platforms(["iOS", "macOS", "visionOS"]))
    }

    @Test("Decode circles only")
    func decodeCirclesOnly() throws {
        let json = Data(#"{"circles":false}"#.utf8)
        let platforms = try JSONDecoder().decode(SupportedPlatforms.self, from: json)
        #expect(platforms.circles == false)
        #expect(platforms.squares == nil)
    }

    @Test("Encode shared squares")
    func encodeShared() throws {
        let platforms = SupportedPlatforms(circles: true, squares: .shared)
        let data = try JSONEncoder().encode(platforms)
        let string = String(data: data, encoding: .utf8)!
        #expect(string.contains("\"shared\""))
        #expect(string.contains("true"))
    }

    @Test("Encode platforms array")
    func encodePlatformsArray() throws {
        let platforms = SupportedPlatforms(squares: .platforms(["iOS"]))
        let data = try JSONEncoder().encode(platforms)
        let string = String(data: data, encoding: .utf8)!
        #expect(string.contains("platforms"))
        #expect(string.contains("iOS"))
    }

    @Test("Round-trip shared squares", arguments: [
        SupportedPlatforms(circles: true, squares: .shared),
        SupportedPlatforms(circles: false, squares: .platforms(["iOS", "macOS"])),
        SupportedPlatforms(circles: true),
        SupportedPlatforms(squares: .shared),
    ])
    func roundTrip(platforms: SupportedPlatforms) throws {
        let data = try JSONEncoder().encode(platforms)
        let decoded = try JSONDecoder().decode(SupportedPlatforms.self, from: data)
        #expect(decoded == platforms)
    }

    @Test("Unknown squares string throws")
    func unknownSquaresString() {
        let json = Data(#"{"squares":"invalid"}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(SupportedPlatforms.self, from: json)
        }
    }
}
