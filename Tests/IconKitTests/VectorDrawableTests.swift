import Testing
import CoreGraphics
import Foundation
@testable import IconKit

@Suite("VectorDrawable")
struct VectorDrawableTests {

    @Test("Parse VectorDrawable XML with group, clip-path, and path")
    func parseXML() throws {
        let xml = """
        <vector xmlns:android="http://schemas.android.com/apk/res/android"
            android:width="108dp"
            android:height="108dp"
            android:viewportWidth="108"
            android:viewportHeight="108"
            android:alpha="0.8"
            android:tint="#FF0000"
            android:tintMode="src_in">
            <group
                android:name="group1"
                android:rotation="45"
                android:pivotX="10"
                android:pivotY="10"
                android:scaleX="0.5"
                android:scaleY="0.5"
                android:translateX="27"
                android:translateY="27">
                <clip-path
                    android:name="clip1"
                    android:pathData="M0,0h50v50h-50z"/>
                <path
                    android:name="path1"
                    android:fillColor="#FF0000"
                    android:fillAlpha="0.7"
                    android:fillType="evenOdd"
                    android:strokeColor="#00FF00"
                    android:strokeWidth="2.5"
                    android:strokeAlpha="0.9"
                    android:strokeLineCap="round"
                    android:strokeLineJoin="bevel"
                    android:strokeMiterLimit="5.0"
                    android:pathData="M0,0h108v108h-108z" />
            </group>
        </vector>
        """
        let vector = try VectorDrawable(xmlData: Data(xml.utf8))
        #expect(vector.width == 108)
        #expect(vector.height == 108)
        #expect(vector.viewportWidth == 108)
        #expect(vector.viewportHeight == 108)
        #expect(vector.alpha == 0.8)
        #expect(vector.tint == "#FF0000")
        #expect(vector.tintMode == "src_in")
        #expect(vector.elements.count == 1)

        if case .group(let group) = vector.elements[0] {
            #expect(group.name == "group1")
            #expect(group.rotation == 45)
            #expect(group.pivotX == 10)
            #expect(group.pivotY == 10)
            #expect(group.scaleX == 0.5)
            #expect(group.scaleY == 0.5)
            #expect(group.translateX == 27)
            #expect(group.translateY == 27)
            #expect(group.children.count == 2)

            if case .clipPath(let clip) = group.children[0] {
                #expect(clip.name == "clip1")
                #expect(clip.pathData == "M0,0h50v50h-50z")
            } else {
                Issue.record("Expected clipPath")
            }

            if case .path(let path) = group.children[1] {
                #expect(path.name == "path1")
                #expect(path.fillColor == "#FF0000")
                #expect(path.fillAlpha == 0.7)
                #expect(path.fillType == .evenOdd)
                #expect(path.strokeColor == "#00FF00")
                #expect(path.strokeWidth == 2.5)
                #expect(path.strokeAlpha == 0.9)
                #expect(path.strokeLineCap == .round)
                #expect(path.strokeLineJoin == .bevel)
                #expect(path.strokeMiterLimit == 5.0)
                #expect(path.pathData == "M0,0h108v108h-108z")
            } else {
                Issue.record("Expected path inside group")
            }
        } else {
            Issue.record("Expected group element")
        }
    }

    @Test("Parse VectorDrawable with inline aapt gradient")
    func parseGradient() throws {
        let xml = """
        <vector xmlns:android="http://schemas.android.com/apk/res/android"
                xmlns:aapt="http://schemas.android.com/aapt"
                android:width="108dp"
                android:height="108dp">
            <path android:pathData="M0,0h108v108h-108z">
                <aapt:attr name="android:fillColor">
                    <gradient
                            android:startY="0"
                            android:startX="54"
                            android:endY="108"
                            android:endX="54"
                            android:type="linear">
                        <item android:offset="0" android:color="#FFC8C1B8"/>
                        <item android:offset="1" android:color="#FFB2A69A"/>
                    </gradient>
                </aapt:attr>
            </path>
        </vector>
        """
        let vector = try VectorDrawable(xmlData: Data(xml.utf8))
        #expect(vector.elements.count == 1)
        if case .path(let path) = vector.elements[0] {
            #expect(path.fillGradient != nil)
            let grad = path.fillGradient!
            #expect(grad.type == .linear)
            #expect(grad.startY == 0)
            #expect(grad.endY == 108)
            #expect(grad.stops.count == 2)
            #expect(grad.stops[0].offset == 0)
            #expect(grad.stops[0].color == "#FFC8C1B8")
            #expect(grad.stops[1].offset == 1)
            #expect(grad.stops[1].color == "#FFB2A69A")
        } else {
            Issue.record("Expected path element")
        }
    }

    @Test("Parse dimension units")
    func parseDimensionUnits() throws {
        let units = ["dp", "dip", "sp", "px", "in", "mm", "pt"]
        for unit in units {
            let xml = """
            <vector xmlns:android="http://schemas.android.com/apk/res/android"
                android:width="96\(unit)"
                android:height="96\(unit)">
            </vector>
            """
            let vector = try VectorDrawable(xmlData: Data(xml.utf8))
            #expect(vector.width == 96)
            #expect(vector.height == 96)
        }
    }

    @Test("Invalid VectorDrawable XML throws")
    func invalidXMLThrows() {
        let invalid = "not valid xml"
        #expect(throws: AdaptiveIconError.self) {
            try VectorDrawable(xmlData: Data(invalid.utf8))
        }
    }
}
