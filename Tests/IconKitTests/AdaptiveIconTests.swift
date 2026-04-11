import Testing
import Foundation
@testable import IconKit

@Suite("AdaptiveIcon")
struct AdaptiveIconTests {

    // MARK: - XML Parsing

    @Test("Parse XML with all three layers")
    func parseFullXML() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
            <background android:drawable="@drawable/ic_launcher_background"/>
            <foreground android:drawable="@drawable/ic_launcher_foreground"/>
            <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
        </adaptive-icon>
        """
        let icon = try AdaptiveIcon(xmlData: Data(xml.utf8))
        #expect(icon.background == "@drawable/ic_launcher_background")
        #expect(icon.foreground == "@drawable/ic_launcher_foreground")
        #expect(icon.monochrome == "@drawable/ic_launcher_monochrome")
    }

    @Test("Parse XML with only foreground and background")
    func parseTwoLayers() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
            <background android:drawable="@mipmap/bg"/>
            <foreground android:drawable="@mipmap/fg"/>
        </adaptive-icon>
        """
        let icon = try AdaptiveIcon(xmlData: Data(xml.utf8))
        #expect(icon.background == "@mipmap/bg")
        #expect(icon.foreground == "@mipmap/fg")
        #expect(icon.monochrome == nil)
    }

    @Test("Parse XML with no foreground")
    func parseNoForeground() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
            <background android:drawable="@drawable/bg"/>
        </adaptive-icon>
        """
        let icon = try AdaptiveIcon(xmlData: Data(xml.utf8))
        #expect(icon.foreground == nil)
        #expect(icon.background == "@drawable/bg")
    }

    @Test("Malformed XML throws")
    func malformedXML() throws {
        let xml = "this is not xml at all <<<"
        #expect(throws: AdaptiveIconError.self) {
            try AdaptiveIcon(xmlData: Data(xml.utf8))
        }
    }

    // MARK: - Drawable Reference Parsing

    @Test("Parse @drawable/ reference")
    func parseDrawableRef() {
        let result = AdaptiveIcon.parseDrawableReference("@drawable/ic_launcher_foreground")
        #expect(result?.type == "drawable")
        #expect(result?.name == "ic_launcher_foreground")
    }

    @Test("Parse @mipmap/ reference")
    func parseMipmapRef() {
        let result = AdaptiveIcon.parseDrawableReference("@mipmap/ic_launcher_background")
        #expect(result?.type == "mipmap")
        #expect(result?.name == "ic_launcher_background")
    }

    @Test("Invalid reference without @ returns nil")
    func invalidRefNoAt() {
        #expect(AdaptiveIcon.parseDrawableReference("drawable/name") == nil)
    }

    @Test("Invalid reference without slash returns nil")
    func invalidRefNoSlash() {
        #expect(AdaptiveIcon.parseDrawableReference("@drawable") == nil)
    }

    // MARK: - XML Serialization

    @Test("XML round-trip preserves layer references")
    func xmlRoundTrip() throws {
        let original = AdaptiveIcon(
            background: "@drawable/bg",
            foreground: "@drawable/fg",
            monochrome: "@drawable/mono"
        )
        let data = original.xmlData()
        let parsed = try AdaptiveIcon(xmlData: data)
        #expect(parsed == original)
    }

    @Test("XML serialization omits nil layers")
    func xmlOmitsNil() {
        let icon = AdaptiveIcon(foreground: "@drawable/fg")
        let xml = String(data: icon.xmlData(), encoding: .utf8)!
        #expect(!xml.contains("background"))
        #expect(xml.contains("foreground"))
        #expect(!xml.contains("monochrome"))
    }
}
