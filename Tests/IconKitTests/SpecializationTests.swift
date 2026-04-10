import Testing
import Foundation
@testable import IconKit

@Suite("Specialization")
struct SpecializationTests {

    // MARK: - Codable

    @Test("Encode and decode specialization with appearance and idiom")
    func encodeDecodeFull() throws {
        let spec = Specialization(appearance: .dark, idiom: .macOS, value: 0.5)
        let data = try JSONEncoder().encode(spec)
        let decoded = try JSONDecoder().decode(Specialization<Double>.self, from: data)
        #expect(decoded == spec)
    }

    @Test("Encode and decode specialization with only appearance")
    func encodeDecodeAppearanceOnly() throws {
        let spec = Specialization(appearance: .tinted, value: true)
        let data = try JSONEncoder().encode(spec)
        let decoded = try JSONDecoder().decode(Specialization<Bool>.self, from: data)
        #expect(decoded == spec)
        #expect(decoded.idiom == nil)
    }

    @Test("Encode and decode specialization with only idiom")
    func encodeDecodeIdiomOnly() throws {
        let spec = Specialization(idiom: .visionOS, value: "glass.svg")
        let data = try JSONEncoder().encode(spec)
        let decoded = try JSONDecoder().decode(Specialization<String>.self, from: data)
        #expect(decoded == spec)
        #expect(decoded.appearance == nil)
    }

    @Test("Encode and decode default specialization (both nil)")
    func encodeDecodeDefault() throws {
        let spec = Specialization<String>(value: "fallback.png")
        let data = try JSONEncoder().encode(spec)
        let decoded = try JSONDecoder().decode(Specialization<String>.self, from: data)
        #expect(decoded == spec)
        #expect(decoded.appearance == nil)
        #expect(decoded.idiom == nil)
    }

    @Test("Specialization with IconFill value round-trips")
    func fillSpecialization() throws {
        let spec = Specialization(
            appearance: .dark,
            value: IconFill.solid(IconColor(colorSpace: .sRGB, components: [0.0, 0.0, 0.0, 1.0]))
        )
        let data = try JSONEncoder().encode(spec)
        let decoded = try JSONDecoder().decode(Specialization<IconFill>.self, from: data)
        #expect(decoded == spec)
    }

    // MARK: - Resolution

    @Test("Exact match wins over all others")
    func resolveExactMatch() {
        let specializations = [
            Specialization(appearance: .dark, idiom: .macOS, value: "exact"),
            Specialization(appearance: .dark, value: "appearance-only"),
            Specialization(idiom: .macOS, value: "idiom-only"),
            Specialization<String>(value: "default"),
        ]
        let result = resolveSpecialization(
            base: "base",
            specializations: specializations,
            appearance: .dark,
            idiom: .macOS
        )
        #expect(result == "exact")
    }

    @Test("Appearance-only match wins over idiom-only")
    func resolveAppearanceOnly() {
        let specializations = [
            Specialization(appearance: .dark, value: "appearance-only"),
            Specialization(idiom: .macOS, value: "idiom-only"),
            Specialization<String>(value: "default"),
        ]
        let result = resolveSpecialization(
            base: "base",
            specializations: specializations,
            appearance: .dark,
            idiom: .macOS
        )
        #expect(result == "appearance-only")
    }

    @Test("Idiom-only match wins over default")
    func resolveIdiomOnly() {
        let specializations = [
            Specialization(idiom: .iOS, value: "idiom-only"),
            Specialization<String>(value: "default"),
        ]
        let result = resolveSpecialization(
            base: "base",
            specializations: specializations,
            appearance: .light,
            idiom: .iOS
        )
        #expect(result == "idiom-only")
    }

    @Test("Default specialization wins over base")
    func resolveDefault() {
        let specializations = [
            Specialization(appearance: .tinted, value: "tinted-only"),
            Specialization<String>(value: "default"),
        ]
        let result = resolveSpecialization(
            base: "base",
            specializations: specializations,
            appearance: .dark,
            idiom: .macOS
        )
        #expect(result == "default")
    }

    @Test("Falls through to base when no match")
    func resolveBase() {
        let specializations = [
            Specialization(appearance: .tinted, idiom: .watchOS, value: "specific"),
        ]
        let result = resolveSpecialization(
            base: "base",
            specializations: specializations,
            appearance: .dark,
            idiom: .macOS
        )
        #expect(result == "base")
    }

    @Test("Empty specializations returns base")
    func resolveEmptySpecializations() {
        let result = resolveSpecialization(
            base: 42,
            specializations: [] as [Specialization<Int>]
        )
        #expect(result == 42)
    }

    @Test("Resolve with no query parameters returns default or base")
    func resolveNoQuery() {
        let specializations = [
            Specialization(appearance: .dark, value: "dark"),
        ]
        let result = resolveSpecialization(
            base: "base",
            specializations: specializations
        )
        #expect(result == "base")
    }

    // MARK: - Appearance and Idiom enums

    @Test("All appearance values round-trip")
    func appearanceRoundTrip() throws {
        for appearance in [Appearance.light, .dark, .tinted] {
            let data = try JSONEncoder().encode(appearance)
            let decoded = try JSONDecoder().decode(Appearance.self, from: data)
            #expect(decoded == appearance)
        }
    }

    @Test("All idiom values round-trip")
    func idiomRoundTrip() throws {
        for idiom in [Idiom.square, .macOS, .iOS, .watchOS, .visionOS] {
            let data = try JSONEncoder().encode(idiom)
            let decoded = try JSONDecoder().decode(Idiom.self, from: data)
            #expect(decoded == idiom)
        }
    }
}
