import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Renders an SF Symbol as a transparent PNG image suitable for use in `.icon` bundles.
public struct SFSymbolRenderer: Sendable {

    public var style: SFSymbolStyle

    public init(style: SFSymbolStyle) {
        self.style = style
    }

    /// Render the SF Symbol onto a transparent canvas and return PNG data.
    ///
    /// The symbol is scaled to fit within `style.size * canvasSize` while
    /// maintaining its natural aspect ratio, centered on the canvas with
    /// optional fractional offsets.
    ///
    /// - Parameter canvasSize: Canvas width and height in pixels (typically 1024).
    /// - Returns: PNG data for the rendered symbol image.
    public func render(canvasSize: Int) throws -> Data {
        guard let symbolImage = NSImage(
            systemSymbolName: style.symbolName,
            accessibilityDescription: nil
        ) else {
            throw SFSymbolRendererError.symbolNotFound(style.symbolName)
        }

        // Apply foreground color via palette configuration
        guard let fgNSColor = NSColor(cgColor: style.foreground) else {
            throw SFSymbolRendererError.invalidColor
        }
        let colorConfig = NSImage.SymbolConfiguration(paletteColors: [fgNSColor])

        // Use a reference point size to determine the symbol's natural aspect ratio
        let referencePointSize: CGFloat = 100
        let sizeConfig = NSImage.SymbolConfiguration(pointSize: referencePointSize, weight: .regular)
        let combinedConfig = colorConfig.applying(sizeConfig)

        guard let configuredImage = symbolImage.withSymbolConfiguration(combinedConfig) else {
            throw SFSymbolRendererError.cannotConfigureSymbol
        }

        let refSize = configuredImage.size

        // Scale to fit within the target bounding box (maintaining aspect ratio)
        let targetDimension = style.size * Double(canvasSize)
        let scaleFactor: Double
        if refSize.width >= refSize.height {
            scaleFactor = targetDimension / refSize.width
        } else {
            scaleFactor = targetDimension / refSize.height
        }
        let drawWidth = refSize.width * scaleFactor
        let drawHeight = refSize.height * scaleFactor

        // Center on canvas with fractional offsets
        let canvas = Double(canvasSize)
        let drawX = (canvas - drawWidth) / 2.0 + style.offsetX * canvas
        let drawY = (canvas - drawHeight) / 2.0 + style.offsetY * canvas

        // Create CGContext (same pattern as RibbonRenderer)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: canvasSize,
                  height: canvasSize,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            throw SFSymbolRendererError.cannotCreateContext
        }

        context.clear(CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))

        // Draw the symbol through NSGraphicsContext so palette colors resolve correctly
        let drawRect = CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        configuredImage.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        guard let outputImage = context.makeImage() else {
            throw SFSymbolRendererError.cannotCreateImage
        }

        return try encodePNG(outputImage)
    }

    // MARK: - PNG encoding

    private func encodePNG(_ image: CGImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw SFSymbolRendererError.cannotEncodePNG
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw SFSymbolRendererError.cannotEncodePNG
        }
        return data as Data
    }
}

/// Errors from SF Symbol rendering.
public enum SFSymbolRendererError: Error, LocalizedError {
    case symbolNotFound(String)
    case invalidColor
    case cannotConfigureSymbol
    case cannotCreateContext
    case cannotCreateImage
    case cannotEncodePNG

    public var errorDescription: String? {
        switch self {
        case .symbolNotFound(let name): "SF Symbol '\(name)' not found."
        case .invalidColor: "Cannot convert foreground color."
        case .cannotConfigureSymbol: "Cannot apply symbol configuration."
        case .cannotCreateContext: "Cannot create graphics context."
        case .cannotCreateImage: "Cannot create output image."
        case .cannotEncodePNG: "Cannot encode PNG image data."
        }
    }
}
