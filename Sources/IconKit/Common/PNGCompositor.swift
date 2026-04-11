import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Output image format for compositing.
public enum ImageFormat: String, Sendable {
    case png
    case webP

    /// The UTType identifier for this format.
    public var utType: UTType {
        switch self {
        case .png: .png
        case .webP: .webP
        }
    }

    /// Detect the format of image data by inspecting its header bytes.
    public static func detect(from data: Data) -> ImageFormat? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let utIdentifier = CGImageSourceGetType(source) as? String else {
            return nil
        }
        if let utType = UTType(utIdentifier) {
            if utType.conforms(to: .webP) { return .webP }
            if utType.conforms(to: .png) { return .png }
        }
        return nil
    }
}

/// Composites a transparent overlay on top of a base image.
public enum ImageCompositor {

    /// Composite the overlay on top of the base image.
    ///
    /// Both images are drawn at the base image's dimensions. If the overlay differs
    /// in size, it is scaled to match. Input format is auto-detected (PNG, WebP, etc.).
    ///
    /// - Parameters:
    ///   - base: Image data for the base (bottom) image.
    ///   - overlay: Image data for the overlay (top) image.
    ///   - outputFormat: The format for the output image. Default: `.png`.
    /// - Returns: Encoded image data for the composited result.
    public static func composite(
        base: Data,
        overlay: Data,
        outputFormat: ImageFormat = .png
    ) throws -> Data {
        let baseImage = try decodeImage(base, label: "base")
        let overlayImage = try decodeImage(overlay, label: "overlay")

        let width = baseImage.width
        let height = baseImage.height

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            throw ImageCompositorError.cannotCreateContext
        }

        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(baseImage, in: rect)
        context.draw(overlayImage, in: rect)

        guard let result = context.makeImage() else {
            throw ImageCompositorError.cannotCreateImage
        }

        return try encodeImage(result, format: outputFormat)
    }

    // MARK: - Private

    private static func decodeImage(_ data: Data, label: String) throws -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ImageCompositorError.cannotDecodeImage(label)
        }
        return image
    }

    private static func encodeImage(_ image: CGImage, format: ImageFormat) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            format.utType.identifier as CFString,
            1,
            nil
        ) else {
            throw ImageCompositorError.cannotEncodeImage(format.rawValue)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ImageCompositorError.cannotEncodeImage(format.rawValue)
        }
        return data as Data
    }
}

/// Backwards compatibility alias.
public typealias PNGCompositor = ImageCompositor

/// Errors from image compositing.
public enum ImageCompositorError: Error, LocalizedError {
    case cannotDecodeImage(String)
    case cannotCreateContext
    case cannotCreateImage
    case cannotEncodeImage(String)

    public var errorDescription: String? {
        switch self {
        case .cannotDecodeImage(let label):
            "Cannot decode \(label) image."
        case .cannotCreateContext:
            "Cannot create graphics context."
        case .cannotCreateImage:
            "Cannot create output image."
        case .cannotEncodeImage(let format):
            "Cannot encode \(format) image data."
        }
    }
}

/// Backwards compatibility alias.
public typealias PNGCompositorError = ImageCompositorError
