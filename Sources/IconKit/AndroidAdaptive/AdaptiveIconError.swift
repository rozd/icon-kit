import Foundation

/// Errors that can occur when working with Android adaptive icon files.
public enum AdaptiveIconError: Error, LocalizedError {
    /// The XML descriptor file was not found at the expected path.
    case xmlNotFound(URL)
    /// The XML file could not be parsed.
    case invalidXML(String)
    /// The adaptive icon XML has no foreground drawable reference.
    case missingForeground
    /// No foreground PNG images were found in any density directory.
    case noForegroundImages
    /// A drawable reference could not be resolved to a file.
    case cannotResolveDrawable(String)
    /// The res/ directory was not found.
    case resDirectoryNotFound(URL)

    public var errorDescription: String? {
        switch self {
        case .xmlNotFound(let url):
            "Adaptive icon XML not found at '\(url.path)'."
        case .invalidXML(let detail):
            "Invalid adaptive icon XML: \(detail)."
        case .missingForeground:
            "Adaptive icon XML has no foreground drawable reference."
        case .noForegroundImages:
            "No foreground PNG images found in any density directory."
        case .cannotResolveDrawable(let ref):
            "Cannot resolve drawable reference '\(ref)'."
        case .resDirectoryNotFound(let url):
            "Android res/ directory not found at '\(url.path)'."
        }
    }
}
