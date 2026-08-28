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

    @Test("Parse cubic Bézier curves")
    func parseCubic() {
        let pathData = "M 0 0 C 10 20 30 40 50 50 S 90 80 100 100"
        let path = SVGPathParser.parse(pathData)
        let bounds = path.boundingBox
        #expect(bounds.minX >= 0)
        #expect(bounds.maxX <= 100)
    }

    @Test("Parse quadratic Bézier curves")
    func parseQuad() {
        let pathData = "M 0 0 Q 50 100 100 0 T 200 0"
        let path = SVGPathParser.parse(pathData)
        let bounds = path.boundingBox
        #expect(bounds.minX == 0)
        #expect(bounds.maxX == 200)
    }

    @Test("Parse elliptical arc")
    func parseArc() {
        let pathData = "M 100 100 A 25 25 0 0 1 150 100"
        let path = SVGPathParser.parse(pathData)
        let bounds = path.boundingBox
        #expect(bounds.minX >= 100)
        #expect(bounds.maxX <= 150)
    }

    @Test("Parse tight numbers without delimiters")
    func parseTightNumbers() {
        let pathData = "M.5.5L-1.2-3.4 10-20"
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
}
