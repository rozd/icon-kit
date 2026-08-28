import Testing
import CoreGraphics
import Foundation
import ImageIO
@testable import IconKit

@Suite("VectorDrawableRenderer")
struct VectorDrawableRendererTests {

    private func decodeImage(_ data: Data) -> CGImage {
        let source = CGImageSourceCreateWithData(data as CFData, nil)!
        return CGImageSourceCreateImageAtIndex(source, 0, nil)!
    }

    private func samplePixel(_ image: CGImage, x: Int, y: Int) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        var pixel: [UInt8] = [0, 0, 0, 0]
        let context = CGContext(
            data: &pixel, width: 1, height: 1,
            bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.draw(image, in: CGRect(x: -x, y: -(image.height - 1 - y), width: image.width, height: image.height))
        return (
            r: CGFloat(pixel[0]) / 255.0,
            g: CGFloat(pixel[1]) / 255.0,
            b: CGFloat(pixel[2]) / 255.0,
            a: CGFloat(pixel[3]) / 255.0
        )
    }

    @Test("Render simple square vector to PNG")
    func renderSquare() throws {
        let path = VectorPath(
            pathData: "M0,0h100v100h-100z",
            fillColor: "#FF0000"
        )
        let vector = VectorDrawable(
            width: 100,
            height: 100,
            viewportWidth: 100,
            viewportHeight: 100,
            elements: [.path(path)]
        )
        let renderer = VectorDrawableRenderer(vector: vector)
        let pngData = try renderer.renderPNG(width: 200, height: 200)
        let image = decodeImage(pngData)

        #expect(image.width == 200)
        #expect(image.height == 200)

        // Center pixel should be red
        let center = samplePixel(image, x: 100, y: 100)
        #expect(center.r > 0.9)
        #expect(center.a > 0.9)
    }

    @Test("Render vector with group transformation")
    func renderWithGroup() throws {
        let path = VectorPath(
            pathData: "M0,0h50v50h-50z",
            fillColor: "#00FF00"
        )
        let group = VectorGroup(
            translateX: 50,
            translateY: 50,
            children: [.path(path)]
        )
        let vector = VectorDrawable(
            width: 100,
            height: 100,
            viewportWidth: 100,
            viewportHeight: 100,
            elements: [.group(group)]
        )
        let renderer = VectorDrawableRenderer(vector: vector)
        let pngData = try renderer.renderPNG(width: 100, height: 100)
        let image = decodeImage(pngData)

        // (75, 75) is inside translated box
        let inside = samplePixel(image, x: 75, y: 75)
        #expect(inside.g > 0.9)
        #expect(inside.a > 0.9)

        // (10, 10) is outside
        let outside = samplePixel(image, x: 10, y: 10)
        #expect(outside.a < 0.1)
    }
}
