import Testing
import CoreGraphics
import Foundation
@testable import IconKit

@Suite("AndroidColor")
struct AndroidColorTests {

    @Test("Parse 6-digit hex")
    func parse6Hex() {
        let color = AndroidColor.parseHex("#FF8000")!
        let components = color.components!
        #expect(abs(components[0] - 1.0) < 0.01)
        #expect(abs(components[1] - 0.5) < 0.02)
        #expect(abs(components[2] - 0.0) < 0.01)
        #expect(abs(components[3] - 1.0) < 0.01)
    }

    @Test("Parse 8-digit ARGB hex")
    func parse8ARGBHex() {
        // In Android, #AARRGGBB -> AA is alpha!
        let color = AndroidColor.parseHex("#80FF0000")!
        let components = color.components!
        #expect(abs(components[3] - 0.5) < 0.02) // Alpha is ~0.5 (0x80 / 255)
        #expect(abs(components[0] - 1.0) < 0.01) // Red is 1.0
        #expect(abs(components[1] - 0.0) < 0.01) // Green is 0
        #expect(abs(components[2] - 0.0) < 0.01) // Blue is 0
    }

    @Test("Parse 3-digit RGB hex")
    func parse3RGBHex() {
        let color = AndroidColor.parseHex("#F00")!
        let components = color.components!
        #expect(components[0] == 1.0)
        #expect(components[1] == 0.0)
        #expect(components[2] == 0.0)
        #expect(components[3] == 1.0)
    }

    @Test("Parse 4-digit ARGB hex")
    func parse4ARGBHex() {
        // #ARGB -> A=8, R=F, G=0, B=0
        let color = AndroidColor.parseHex("#8F00")!
        let components = color.components!
        #expect(abs(components[3] - (8.0 / 15.0)) < 0.01)
        #expect(components[0] == 1.0)
    }

    @Test("Parse standard Android colors")
    func parseStandardColors() {
        let transparent = AndroidColor.parse("@android:color/transparent")!
        #expect(transparent.components![3] == 0)

        let black = AndroidColor.parse("@android:color/black")!
        #expect(black.components![0] == 0)
        #expect(black.components![3] == 1)

        let white = AndroidColor.parse("@android:color/white")!
        #expect(white.components![0] == 1)
        #expect(white.components![3] == 1)
    }

    @Test("Load colors from values directory")
    func loadColorsFromValuesDir() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("AndroidColorTests-\(UUID().uuidString)")
        let valuesDir = tmp.appendingPathComponent("values")
        try FileManager.default.createDirectory(at: valuesDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <resources>
            <color name="ic_launcher_background">#B2A69A</color>
            <color name="primary">#FF0000</color>
        </resources>
        """
        try Data(xml.utf8).write(to: valuesDir.appendingPathComponent("colors.xml"))

        let colors = AndroidColor.loadColors(from: tmp)
        #expect(colors["@color/ic_launcher_background"] != nil)
        #expect(colors["@color/primary"] != nil)
    }
}
