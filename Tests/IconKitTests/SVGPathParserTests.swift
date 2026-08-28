import Testing
import CoreGraphics
import Foundation
@testable import IconKit

@Suite("SVGPathParser")
struct SVGPathParserTests {

    @Test("Parse simple lines and moveto")
    func parseLines() {
        let pathData = "M 10 20 L 30 40 H 50 V 60 Z"
        let path = SVGPathParser.parse(pathData)
        let bounds = path.boundingBox
        #expect(bounds.minX == 10)
        #expect(bounds.maxX == 50)
        #expect(bounds.minY == 20)
        #expect(bounds.maxY == 60)
    }

    @Test("Parse relative commands")
    func parseRelative() {
        let pathData = "m 10 10 l 20 0 v 20 h -20 z"
        let path = SVGPathParser.parse(pathData)
        let bounds = path.boundingBox
        #expect(bounds.minX == 10)
        #expect(bounds.maxX == 30)
        #expect(bounds.minY == 10)
        #expect(bounds.maxY == 30)
    }

    @Test("Parse cubic Bézier curves (absolute and relative)")
    func parseCubic() {
        let pathData = "M 0 0 C 10 20 30 40 50 50 c 10 20 30 40 50 50 S 140 130 150 150 s 40 30 50 50"
        let path = SVGPathParser.parse(pathData)
        let bounds = path.boundingBox
        #expect(bounds.minX >= 0)
        #expect(bounds.maxX <= 250)
    }

    @Test("Parse smooth cubic S without prior cubic")
    func parseSmoothCubicStandalone() {
        let pathData = "M 10 10 S 30 40 50 50"
        let path = SVGPathParser.parse(pathData)
        let bounds = path.boundingBox
        #expect(bounds.minX >= 10)
        #expect(bounds.maxX <= 50)
    }

    @Test("Parse quadratic Bézier curves (absolute and relative)")
    func parseQuad() {
        let pathData = "M 0 0 Q 50 100 100 0 q 50 -100 100 0 T 300 0 t 100 0"
        let path = SVGPathParser.parse(pathData)
        let bounds = path.boundingBox
        #expect(bounds.minX == 0)
        #expect(bounds.maxX == 400)
    }

    @Test("Parse smooth quad T without prior quad")
    func parseSmoothQuadStandalone() {
        let pathData = "M 10 10 T 50 50"
        let path = SVGPathParser.parse(pathData)
        let bounds = path.boundingBox
        #expect(bounds.minX >= 10)
        #expect(bounds.maxX <= 50)
    }

    @Test("Parse elliptical arc variations")
    func parseArc() {
        // Standard arc
        let pathData1 = "M 100 100 A 25 25 0 0 1 150 100"
        let path1 = SVGPathParser.parse(pathData1)
        #expect(!path1.isEmpty)

        // Relative arc with large arc and sweep = 0
        let pathData2 = "M 100 100 a 25 25 45 1 0 50 0"
        let path2 = SVGPathParser.parse(pathData2)
        #expect(!path2.isEmpty)

        // Arc with rx = 0 (fallback to lineto)
        let pathData3 = "M 0 0 A 0 25 0 0 1 50 50"
        let path3 = SVGPathParser.parse(pathData3)
        #expect(!path3.isEmpty)

        // Arc where start and end points are identical (noop)
        let pathData4 = "M 50 50 A 25 25 0 0 1 50 50"
        let path4 = SVGPathParser.parse(pathData4)
        #expect(!path4.isEmpty)

        // Arc requiring radius scale (lambda > 1)
        let pathData5 = "M 0 0 A 5 5 0 0 1 100 100"
        let path5 = SVGPathParser.parse(pathData5)
        #expect(!path5.isEmpty)
    }

    @Test("Parse scientific notation and tight numbers without delimiters")
    func parseTightNumbers() {
        let pathData = "M.5.5L-1.2-3.4 10-20 1e-4 2.5E+2"
        let path = SVGPathParser.parse(pathData)
        #expect(!path.isEmpty)
    }

    @Test("Parse implicit repeated coordinates")
    func parseImplicitRepeated() {
        let pathData = "M 0 0 10 10 20 20"
        let path = SVGPathParser.parse(pathData)
        let bounds = path.boundingBox
        #expect(bounds.maxX == 20)
        #expect(bounds.maxY == 20)
    }

    @Test("Empty or invalid path data returns empty path")
    func emptyPath() {
        let path = SVGPathParser.parse("")
        #expect(path.isEmpty)
    }
}
