import Testing
import CoreGraphics
import Foundation
@testable import IconKit

@Suite("VectorDrawable")
struct VectorDrawableTests {

    @Test("Parse VectorDrawable XML")
    func parseXML() throws {
        let xml = """
        <vector xmlns:android="http://schemas.android.com/apk/res/android"
            android:width="108dp"
            android:height="108dp"
            android:viewportWidth="108"
            android:viewportHeight="108">
            <group
                android:scaleX="0.5"
                android:scaleY="0.5"
                android:translateX="27"
                android:translateY="27">
                <path
                    android:fillColor="#FF0000"
                    android:pathData="M0,0h108v108h-108z" />
            </group>
        </vector>
        """
        let vector = try VectorDrawable(xmlData: Data(xml.utf8))
        #expect(vector.width == 108)
        #expect(vector.height == 108)
        #expect(vector.viewportWidth == 108)
        #expect(vector.viewportHeight == 108)
        #expect(vector.elements.count == 1)

        if case .group(let group) = vector.elements[0] {
            #expect(group.scaleX == 0.5)
            #expect(group.scaleY == 0.5)
            #expect(group.translateX == 27)
            #expect(group.translateY == 27)
            #expect(group.children.count == 1)
            if case .path(let path) = group.children[0] {
                #expect(path.fillColor == "#FF0000")
                #expect(path.pathData == "M0,0h108v108h-108z")
            } else {
                Issue.record("Expected path inside group")
            }
        } else {
            Issue.record("Expected group element")
        }
    }
}
