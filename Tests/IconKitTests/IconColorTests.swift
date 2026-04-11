import Testing
import Foundation
@testable import IconKit

@Suite("IconColor")
struct IconColorTests {

    // MARK: - Parsing

    @Test("Parse sRGB color")
    func parseSRGB() throws {
        let color = try IconColor(parsing: "srgb:0.0,0.5,1.0,0.8")
        #expect(color.colorSpace == .sRGB)
        #expect(color.components == [0.0, 0.5, 1.0, 0.8])
        #expect(color.red == 0.0)
        #expect(color.green == 0.5)
        #expect(color.blue == 1.0)
        #expect(color.alpha == 0.8)
    }

    @Test("Parse extended sRGB color")
    func parseExtendedSRGB() throws {
        let color = try IconColor(parsing: "extended-srgb:0.0,0.0,0.0,1.0")
        #expect(color.colorSpace == .extendedSRGB)
        #expect(color.components == [0.0, 0.0, 0.0, 1.0])
    }

    @Test("Parse Display P3 color")
    func parseDisplayP3() throws {
        let color = try IconColor(parsing: "display-p3:1.0,0.0,0.0,1.0")
        #expect(color.colorSpace == .displayP3)
        #expect(color.components == [1.0, 0.0, 0.0, 1.0])
    }

    @Test("Parse gray color")
    func parseGray() throws {
        let color = try IconColor(parsing: "gray:0.5,1.0")
        #expect(color.colorSpace == .gray)
        #expect(color.components == [0.5, 1.0])
        #expect(color.luminance == 0.5)
        #expect(color.alpha == 1.0)
        #expect(color.red == nil)
    }

    @Test("Parse extended gray color")
    func parseExtendedGray() throws {
        let color = try IconColor(parsing: "extended-gray:0.75,0.9")
        #expect(color.colorSpace == .extendedGray)
        #expect(color.components == [0.75, 0.9])
        #expect(color.luminance == 0.75)
        #expect(color.alpha == 0.9)
    }

    // MARK: - String representation

    @Test("String representation round-trips")
    func stringRepresentation() throws {
        let color = try IconColor(parsing: "srgb:1.0,0.0,0.0,1.0")
        #expect(color.stringRepresentation == "srgb:1.00000,0.00000,0.00000,1.00000")
    }

    @Test("String representation for gray")
    func stringRepresentationGray() throws {
        let color = try IconColor(parsing: "gray:0.5,1.0")
        #expect(color.stringRepresentation == "gray:0.50000,1.00000")
    }

    // MARK: - JSON Codable

    @Test("JSON encode and decode round-trip")
    func jsonRoundTrip() throws {
        let original = try IconColor(parsing: "display-p3:0.25,0.5,0.75,1.0")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(IconColor.self, from: data)
        #expect(decoded == original)
    }

    @Test("JSON decodes from string")
    func jsonDecodeFromString() throws {
        let json = Data(#""srgb:1.0,0.0,0.0,1.0""#.utf8)
        let color = try JSONDecoder().decode(IconColor.self, from: json)
        #expect(color.colorSpace == .sRGB)
        #expect(color.components == [1.0, 0.0, 0.0, 1.0])
    }

    @Test("JSON encodes as string")
    func jsonEncodeAsString() throws {
        let color = IconColor(colorSpace: .sRGB, components: [1.0, 0.0, 0.0, 1.0])
        let data = try JSONEncoder().encode(color)
        let string = String(data: data, encoding: .utf8)!
        #expect(string == #""srgb:1.00000,0.00000,0.00000,1.00000""#)
    }

    // MARK: - Error cases

    @Test("Parsing invalid format throws")
    func invalidFormat() {
        #expect(throws: IconColorError.self) {
            try IconColor(parsing: "bad")
        }
    }

    @Test("Parsing unknown color space throws")
    func unknownColorSpace() {
        #expect(throws: IconColorError.self) {
            try IconColor(parsing: "cmyk:1.0,0.0,0.0,0.0")
        }
    }

    @Test("Wrong component count for gray throws")
    func wrongComponentCountGray() {
        #expect(throws: IconColorError.self) {
            try IconColor(parsing: "gray:0.5,0.5,0.5")
        }
    }

    @Test("Wrong component count for sRGB throws")
    func wrongComponentCountSRGB() {
        #expect(throws: IconColorError.self) {
            try IconColor(parsing: "srgb:1.0,0.0")
        }
    }

    @Test("Invalid component value throws")
    func invalidComponent() {
        #expect(throws: IconColorError.self) {
            try IconColor(parsing: "srgb:abc,0.0,0.0,1.0")
        }
    }

    // MARK: - Hashable

    @Test("Equal colors are equal")
    func equality() throws {
        let a = try IconColor(parsing: "srgb:1.0,0.0,0.0,1.0")
        let b = try IconColor(parsing: "srgb:1.0,0.0,0.0,1.0")
        #expect(a == b)
    }

    @Test("Different colors are not equal")
    func inequality() throws {
        let a = try IconColor(parsing: "srgb:1.0,0.0,0.0,1.0")
        let b = try IconColor(parsing: "srgb:0.0,1.0,0.0,1.0")
        #expect(a != b)
    }
}
