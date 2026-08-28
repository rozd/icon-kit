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
        let a = CGFloat(pixel[3]) / 255.0
        // Un-premultiply RGB if alpha > 0
        let r = a > 0 ? (CGFloat(pixel[0]) / 255.0) / a : 0
        let g = a > 0 ? (CGFloat(pixel[1]) / 255.0) / a : 0
        let b = a > 0 ? (CGFloat(pixel[2]) / 255.0) / a : 0
        return (r: r, g: g, b: b, a: a)
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

    @Test("Render vector with group transformation and rotation")
    func renderWithGroup() throws {
        let path = VectorPath(
            pathData: "M0,0h50v50h-50z",
            fillColor: "#00FF00"
        )
        let group = VectorGroup(
            rotation: 45,
            pivotX: 25,
            pivotY: 25,
            scaleX: 1.5,
            scaleY: 1.5,
            translateX: 20,
            translateY: 20,
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

        // Center of transformed group (around 45, 45) should be green
        let center = samplePixel(image, x: 45, y: 45)
        #expect(center.g > 0.9)
        #expect(center.a > 0.9)

        // (0, 0) should be transparent
        let corner = samplePixel(image, x: 0, y: 0)
        #expect(corner.a < 0.1)
    }

    @Test("Render vector with stroke, linecap, and join")
    func renderStroke() throws {
        let path = VectorPath(
            pathData: "M10,50 L90,50",
            strokeColor: "#0000FF",
            strokeWidth: 10,
            strokeAlpha: 0.8,
            strokeLineCap: .round,
            strokeLineJoin: .round
        )
        let vector = VectorDrawable(
            width: 100,
            height: 100,
            elements: [.path(path)]
        )
        let renderer = VectorDrawableRenderer(vector: vector)
        let pngData = try renderer.renderPNG(width: 100, height: 100)
        let image = decodeImage(pngData)

        let mid = samplePixel(image, x: 50, y: 50)
        #expect(mid.b > 0.9)
        #expect(mid.a > 0.7 && mid.a < 0.9)
    }

    @Test("Render vector with fillAlpha and evenOdd fillType")
    func renderFillAlphaAndEvenOdd() throws {
        // Two concentric squares with even-odd fill -> donut hole in center
        let path = VectorPath(
            pathData: "M0,0 h100 v100 h-100 z M25,25 h50 v50 h-50 z",
            fillColor: "#FF0000",
            fillAlpha: 0.5,
            fillType: .evenOdd
        )
        let vector = VectorDrawable(
            width: 100,
            height: 100,
            elements: [.path(path)]
        )
        let renderer = VectorDrawableRenderer(vector: vector)
        let pngData = try renderer.renderPNG(width: 100, height: 100)
        let image = decodeImage(pngData)

        // Outer area should have alpha ~0.5 and red color ~1.0
        let outer = samplePixel(image, x: 10, y: 10)
        #expect(outer.r > 0.9)
        #expect(outer.a > 0.4 && outer.a < 0.6)

        // Inner hole should be transparent due to evenOdd fill
        let inner = samplePixel(image, x: 50, y: 50)
        #expect(inner.a < 0.1)
    }

    @Test("Render vector with clip-path")
    func renderClipPath() throws {
        let clip = VectorClipPath(pathData: "M0,0 h50 v100 h-50 z")
        let path = VectorPath(
            pathData: "M0,0 h100 v100 h-100 z",
            fillColor: "#0000FF"
        )
        let group = VectorGroup(children: [.clipPath(clip), .path(path)])
        let vector = VectorDrawable(
            width: 100,
            height: 100,
            elements: [.group(group)]
        )
        let renderer = VectorDrawableRenderer(vector: vector)
        let pngData = try renderer.renderPNG(width: 100, height: 100)
        let image = decodeImage(pngData)

        // Left half (clipped in) is blue
        let left = samplePixel(image, x: 25, y: 50)
        #expect(left.b > 0.9)
        #expect(left.a > 0.9)

        // Right half (clipped out) is transparent
        let right = samplePixel(image, x: 75, y: 50)
        #expect(right.a < 0.1)
    }

    @Test("Render vector with vector-level alpha")
    func renderVectorAlpha() throws {
        let path = VectorPath(
            pathData: "M0,0 h100 v100 h-100 z",
            fillColor: "#FFFFFF"
        )
        let vector = VectorDrawable(
            width: 100,
            height: 100,
            alpha: 0.4,
            elements: [.path(path)]
        )
        let renderer = VectorDrawableRenderer(vector: vector)
        let pngData = try renderer.renderPNG(width: 100, height: 100)
        let image = decodeImage(pngData)

        let pixel = samplePixel(image, x: 50, y: 50)
        #expect(pixel.a > 0.3 && pixel.a < 0.5)
    }
}
