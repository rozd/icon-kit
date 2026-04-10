import Testing
import Foundation
@testable import IconKit

@Suite("IconFill")
struct IconFillTests {

    // MARK: - Decoding

    @Test("Decode automatic fill")
    func decodeAutomatic() throws {
        let json = Data(#""automatic""#.utf8)
        let fill = try JSONDecoder().decode(IconFill.self, from: json)
        #expect(fill == .automatic)
    }

    @Test("Decode system-light fill")
    func decodeSystemLight() throws {
        let json = Data(#""system-light""#.utf8)
        let fill = try JSONDecoder().decode(IconFill.self, from: json)
        #expect(fill == .systemLight)
    }

    @Test("Decode system-dark fill")
    func decodeSystemDark() throws {
        let json = Data(#""system-dark""#.utf8)
        let fill = try JSONDecoder().decode(IconFill.self, from: json)
        #expect(fill == .systemDark)
    }

    @Test("Decode solid fill")
    func decodeSolid() throws {
        let json = Data(#"{"solid":"srgb:1.0,0.0,0.0,1.0"}"#.utf8)
        let fill = try JSONDecoder().decode(IconFill.self, from: json)
        let expected = IconFill.solid(IconColor(colorSpace: .sRGB, components: [1.0, 0.0, 0.0, 1.0]))
        #expect(fill == expected)
    }

    @Test("Decode automatic-gradient fill")
    func decodeAutomaticGradient() throws {
        let json = Data(#"{"automatic-gradient":"display-p3:0.5,0.5,0.5,1.0"}"#.utf8)
        let fill = try JSONDecoder().decode(IconFill.self, from: json)
        let expected = IconFill.automaticGradient(IconColor(colorSpace: .displayP3, components: [0.5, 0.5, 0.5, 1.0]))
        #expect(fill == expected)
    }

    // MARK: - Encoding

    @Test("Encode automatic fill")
    func encodeAutomatic() throws {
        let data = try JSONEncoder().encode(IconFill.automatic)
        let string = String(data: data, encoding: .utf8)!
        #expect(string == #""automatic""#)
    }

    @Test("Encode system-light fill")
    func encodeSystemLight() throws {
        let data = try JSONEncoder().encode(IconFill.systemLight)
        let string = String(data: data, encoding: .utf8)!
        #expect(string == #""system-light""#)
    }

    @Test("Encode system-dark fill")
    func encodeSystemDark() throws {
        let data = try JSONEncoder().encode(IconFill.systemDark)
        let string = String(data: data, encoding: .utf8)!
        #expect(string == #""system-dark""#)
    }

    @Test("Encode solid fill")
    func encodeSolid() throws {
        let fill = IconFill.solid(IconColor(colorSpace: .sRGB, components: [1.0, 0.0, 0.0, 1.0]))
        let data = try JSONEncoder().encode(fill)
        let string = String(data: data, encoding: .utf8)!
        #expect(string.contains("solid"))
        #expect(string.contains("srgb:1.0,0.0,0.0,1.0"))
    }

    @Test("Encode automatic-gradient fill")
    func encodeAutomaticGradient() throws {
        let fill = IconFill.automaticGradient(IconColor(colorSpace: .displayP3, components: [0.5, 0.5, 0.5, 1.0]))
        let data = try JSONEncoder().encode(fill)
        let string = String(data: data, encoding: .utf8)!
        #expect(string.contains("automatic-gradient"))
        #expect(string.contains("display-p3:0.5,0.5,0.5,1.0"))
    }

    // MARK: - Round-trip

    @Test("All fill variants round-trip", arguments: [
        IconFill.automatic,
        IconFill.systemLight,
        IconFill.systemDark,
        IconFill.solid(IconColor(colorSpace: .sRGB, components: [1.0, 0.0, 0.0, 1.0])),
        IconFill.automaticGradient(IconColor(colorSpace: .gray, components: [0.5, 1.0])),
    ])
    func roundTrip(fill: IconFill) throws {
        let data = try JSONEncoder().encode(fill)
        let decoded = try JSONDecoder().decode(IconFill.self, from: data)
        #expect(decoded == fill)
    }

    // MARK: - Error cases

    @Test("Decode unknown string throws")
    func unknownString() {
        let json = Data(#""invalid""#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(IconFill.self, from: json)
        }
    }
}
