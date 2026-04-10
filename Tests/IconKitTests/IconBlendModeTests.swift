import Testing
import Foundation
@testable import IconKit

@Suite("IconBlendMode")
struct IconBlendModeTests {

    @Test("All blend modes decode from raw values", arguments: [
        ("normal", IconBlendMode.normal),
        ("multiply", IconBlendMode.multiply),
        ("screen", IconBlendMode.screen),
        ("overlay", IconBlendMode.overlay),
        ("darken", IconBlendMode.darken),
        ("lighten", IconBlendMode.lighten),
        ("color-dodge", IconBlendMode.colorDodge),
        ("color-burn", IconBlendMode.colorBurn),
        ("soft-light", IconBlendMode.softLight),
        ("hard-light", IconBlendMode.hardLight),
        ("difference", IconBlendMode.difference),
        ("exclusion", IconBlendMode.exclusion),
        ("hue", IconBlendMode.hue),
        ("saturation", IconBlendMode.saturation),
        ("color", IconBlendMode.color),
        ("luminosity", IconBlendMode.luminosity),
        ("plus-darker", IconBlendMode.plusDarker),
        ("plus-lighter", IconBlendMode.plusLighter),
    ] as [(String, IconBlendMode)])
    func decodeBlendMode(rawValue: String, expected: IconBlendMode) throws {
        let json = Data("\"\(rawValue)\"".utf8)
        let decoded = try JSONDecoder().decode(IconBlendMode.self, from: json)
        #expect(decoded == expected)
    }

    @Test("All blend modes round-trip", arguments: [
        IconBlendMode.normal, .multiply, .screen, .overlay,
        .darken, .lighten, .colorDodge, .colorBurn,
        .softLight, .hardLight, .difference, .exclusion,
        .hue, .saturation, .color, .luminosity,
        .plusDarker, .plusLighter,
    ])
    func roundTrip(mode: IconBlendMode) throws {
        let data = try JSONEncoder().encode(mode)
        let decoded = try JSONDecoder().decode(IconBlendMode.self, from: data)
        #expect(decoded == mode)
    }

    @Test("Unknown blend mode throws")
    func unknownBlendMode() {
        let json = Data(#""dissolve""#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(IconBlendMode.self, from: json)
        }
    }
}
