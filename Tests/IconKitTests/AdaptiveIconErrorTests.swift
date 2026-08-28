import Testing
import Foundation
@testable import IconKit

@Suite("AdaptiveIconError")
struct AdaptiveIconErrorTests {

    @Test("All error descriptions are non-empty and descriptive")
    func errorDescriptions() {
        let url = URL(fileURLWithPath: "/path/to/res")
        let xmlURL = URL(fileURLWithPath: "/path/to/icon.xml")

        let errors: [AdaptiveIconError] = [
            .xmlNotFound(xmlURL),
            .invalidXML("bad token"),
            .missingForeground,
            .noForegroundImages,
            .cannotResolveDrawable("@drawable/missing"),
            .resDirectoryNotFound(url),
        ]

        for error in errors {
            let desc = error.errorDescription
            #expect(desc != nil)
            #expect(!desc!.isEmpty)
        }

        #expect(AdaptiveIconError.xmlNotFound(xmlURL).errorDescription!.contains("/path/to/icon.xml"))
        #expect(AdaptiveIconError.invalidXML("bad token").errorDescription!.contains("bad token"))
        #expect(AdaptiveIconError.missingForeground.errorDescription!.contains("foreground"))
        #expect(AdaptiveIconError.noForegroundImages.errorDescription!.contains("No foreground images"))
        #expect(AdaptiveIconError.cannotResolveDrawable("@drawable/missing").errorDescription!.contains("@drawable/missing"))
        #expect(AdaptiveIconError.resDirectoryNotFound(url).errorDescription!.contains("/path/to/res"))
    }
}
