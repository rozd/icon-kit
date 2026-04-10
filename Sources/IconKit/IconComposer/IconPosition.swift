/// Position and scale transform for an icon layer.
public struct IconPosition: Codable, Hashable, Sendable {

    /// Scale factor. 1.0 means original size.
    public var scale: Double

    /// Translation offset in points as `[x, y]`.
    public var translationInPoints: [Double]

    public init(scale: Double = 1.0, translationInPoints: [Double] = [0.0, 0.0]) {
        self.scale = scale
        self.translationInPoints = translationInPoints
    }

    public var translationX: Double {
        translationInPoints.count >= 1 ? translationInPoints[0] : 0.0
    }

    public var translationY: Double {
        translationInPoints.count >= 2 ? translationInPoints[1] : 0.0
    }

    public static let identity = IconPosition()

    enum CodingKeys: String, CodingKey {
        case scale
        case translationInPoints = "translation-in-points"
    }
}
