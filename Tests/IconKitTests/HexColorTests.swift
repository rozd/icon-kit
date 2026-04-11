import Testing
import CoreGraphics
@testable import IconKit

@Suite("HexColor")
struct HexColorTests {

    @Test("Parse 6-digit hex with # prefix")
    func parseWithHash() throws {
        let color = try parseHexColor("#FF0000")
        let components = color.components!
        #expect(components[0] == 1.0) // red
        #expect(components[1] == 0.0) // green
        #expect(components[2] == 0.0) // blue
        #expect(components[3] == 1.0) // alpha
    }

    @Test("Parse 6-digit hex without # prefix")
    func parseWithoutHash() throws {
        let color = try parseHexColor("00FF00")
        let components = color.components!
        #expect(components[0] == 0.0)
        #expect(components[1] == 1.0)
        #expect(components[2] == 0.0)
        #expect(components[3] == 1.0)
    }

    @Test("Parse 8-digit hex with alpha")
    func parseWithAlpha() throws {
        let color = try parseHexColor("#0000FF80")
        let components = color.components!
        #expect(components[0] == 0.0)
        #expect(components[1] == 0.0)
        #expect(abs(components[2] - 1.0) < 0.01)
        #expect(abs(components[3] - 128.0 / 255.0) < 0.01)
    }

    @Test("Parse black")
    func parseBlack() throws {
        let color = try parseHexColor("#000000")
        let components = color.components!
        #expect(components[0] == 0.0)
        #expect(components[1] == 0.0)
        #expect(components[2] == 0.0)
        #expect(components[3] == 1.0)
    }

    @Test("Parse white")
    func parseWhite() throws {
        let color = try parseHexColor("#FFFFFF")
        let components = color.components!
        #expect(components[0] == 1.0)
        #expect(components[1] == 1.0)
        #expect(components[2] == 1.0)
        #expect(components[3] == 1.0)
    }

    @Test("Parse mixed hex values")
    func parseMixed() throws {
        let color = try parseHexColor("#E0D1BA")
        let components = color.components!
        #expect(abs(components[0] - 224.0 / 255.0) < 0.01)
        #expect(abs(components[1] - 209.0 / 255.0) < 0.01)
        #expect(abs(components[2] - 186.0 / 255.0) < 0.01)
    }

    @Test("Parse lowercase hex")
    func parseLowercase() throws {
        let color = try parseHexColor("#ff0000")
        let components = color.components!
        #expect(components[0] == 1.0)
    }

    // MARK: - Error cases

    @Test("Empty string throws")
    func emptyString() {
        #expect(throws: HexColorError.self) {
            try parseHexColor("")
        }
    }

    @Test("Wrong length throws")
    func wrongLength() {
        #expect(throws: HexColorError.self) {
            try parseHexColor("#FFF")
        }
    }

    @Test("Invalid hex characters throws")
    func invalidChars() {
        #expect(throws: HexColorError.self) {
            try parseHexColor("#GGGGGG")
        }
    }

    @Test("Just hash throws")
    func justHash() {
        #expect(throws: HexColorError.self) {
            try parseHexColor("#")
        }
    }

    // MARK: - parseHexIconColor

    @Test("parseHexIconColor returns sRGB IconColor")
    func parseHexIconColorSRGB() throws {
        let color = try parseHexIconColor("#FF0000")
        #expect(color.colorSpace == .sRGB)
        #expect(color.components.count == 4)
        #expect(color.components[0] == 1.0) // red
        #expect(color.components[1] == 0.0) // green
        #expect(color.components[2] == 0.0) // blue
        #expect(color.components[3] == 1.0) // alpha
    }

    @Test("parseHexIconColor preserves alpha from 8-digit hex")
    func parseHexIconColorAlpha() throws {
        let color = try parseHexIconColor("#0000FF80")
        #expect(color.colorSpace == .sRGB)
        #expect(color.components[0] == 0.0)
        #expect(color.components[1] == 0.0)
        #expect(abs(color.components[2] - 1.0) < 0.01)
        #expect(abs(color.components[3] - 128.0 / 255.0) < 0.01)
    }

    @Test("parseHexIconColor propagates errors for invalid input")
    func parseHexIconColorInvalid() {
        #expect(throws: HexColorError.self) {
            try parseHexIconColor("#GGG")
        }
    }
}
