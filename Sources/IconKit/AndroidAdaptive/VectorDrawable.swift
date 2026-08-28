import CoreGraphics
import Foundation

/// Model of an Android `<vector>` drawable XML.
public struct VectorDrawable: Sendable {
    public var width: Double
    public var height: Double
    public var viewportWidth: Double
    public var viewportHeight: Double
    public var alpha: Double
    public var tint: String?
    public var tintMode: String?
    public var elements: [VectorElement]

    public init(
        width: Double = 108,
        height: Double = 108,
        viewportWidth: Double? = nil,
        viewportHeight: Double? = nil,
        alpha: Double = 1.0,
        tint: String? = nil,
        tintMode: String? = nil,
        elements: [VectorElement] = []
    ) {
        self.width = width
        self.height = height
        self.viewportWidth = viewportWidth ?? width
        self.viewportHeight = viewportHeight ?? height
        self.alpha = alpha
        self.tint = tint
        self.tintMode = tintMode
        self.elements = elements
    }

    /// Parse a VectorDrawable from XML data.
    public init(xmlData: Data) throws {
        let parser = VectorDrawableXMLParser()
        self = try parser.parse(data: xmlData)
    }
}

/// An element within a vector drawable tree.
public enum VectorElement: Sendable {
    case group(VectorGroup)
    case path(VectorPath)
    case clipPath(VectorClipPath)
}

/// A `<group>` element in a VectorDrawable.
public struct VectorGroup: Sendable {
    public var name: String?
    public var rotation: Double
    public var pivotX: Double
    public var pivotY: Double
    public var scaleX: Double
    public var scaleY: Double
    public var translateX: Double
    public var translateY: Double
    public var children: [VectorElement]

    public init(
        name: String? = nil,
        rotation: Double = 0,
        pivotX: Double = 0,
        pivotY: Double = 0,
        scaleX: Double = 1,
        scaleY: Double = 1,
        translateX: Double = 0,
        translateY: Double = 0,
        children: [VectorElement] = []
    ) {
        self.name = name
        self.rotation = rotation
        self.pivotX = pivotX
        self.pivotY = pivotY
        self.scaleX = scaleX
        self.scaleY = scaleY
        self.translateX = translateX
        self.translateY = translateY
        self.children = children
    }
}

/// A gradient specification in a VectorDrawable.
public struct VectorGradient: Sendable, Equatable {
    public enum GradientType: String, Sendable {
        case linear
        case radial
        case sweep
    }

    public struct Stop: Sendable, Equatable {
        public var offset: Double
        public var color: String

        public init(offset: Double, color: String) {
            self.offset = offset
            self.color = color
        }
    }

    public var type: GradientType
    public var startX: Double
    public var startY: Double
    public var endX: Double
    public var endY: Double
    public var centerX: Double
    public var centerY: Double
    public var gradientRadius: Double
    public var startColor: String?
    public var endColor: String?
    public var centerColor: String?
    public var stops: [Stop]

    public init(
        type: GradientType = .linear,
        startX: Double = 0,
        startY: Double = 0,
        endX: Double = 0,
        endY: Double = 0,
        centerX: Double = 0,
        centerY: Double = 0,
        gradientRadius: Double = 0,
        startColor: String? = nil,
        endColor: String? = nil,
        centerColor: String? = nil,
        stops: [Stop] = []
    ) {
        self.type = type
        self.startX = startX
        self.startY = startY
        self.endX = endX
        self.endY = endY
        self.centerX = centerX
        self.centerY = centerY
        self.gradientRadius = gradientRadius
        self.startColor = startColor
        self.endColor = endColor
        self.centerColor = centerColor
        self.stops = stops
    }
}

/// A `<path>` element in a VectorDrawable.
public struct VectorPath: Sendable {
    public enum FillType: Sendable {
        case nonZero
        case evenOdd
    }

    public var name: String?
    public var pathData: String
    public var fillColor: String?
    public var fillGradient: VectorGradient?
    public var fillAlpha: Double
    public var fillType: FillType
    public var strokeColor: String?
    public var strokeWidth: Double
    public var strokeAlpha: Double
    public var strokeLineCap: CGLineCap
    public var strokeLineJoin: CGLineJoin
    public var strokeMiterLimit: Double
    public var trimPathStart: Double
    public var trimPathEnd: Double
    public var trimPathOffset: Double

    public init(
        name: String? = nil,
        pathData: String = "",
        fillColor: String? = nil,
        fillGradient: VectorGradient? = nil,
        fillAlpha: Double = 1.0,
        fillType: FillType = .nonZero,
        strokeColor: String? = nil,
        strokeWidth: Double = 0,
        strokeAlpha: Double = 1.0,
        strokeLineCap: CGLineCap = .butt,
        strokeLineJoin: CGLineJoin = .miter,
        strokeMiterLimit: Double = 4.0,
        trimPathStart: Double = 0,
        trimPathEnd: Double = 1,
        trimPathOffset: Double = 0
    ) {
        self.name = name
        self.pathData = pathData
        self.fillColor = fillColor
        self.fillGradient = fillGradient
        self.fillAlpha = fillAlpha
        self.fillType = fillType
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.strokeAlpha = strokeAlpha
        self.strokeLineCap = strokeLineCap
        self.strokeLineJoin = strokeLineJoin
        self.strokeMiterLimit = strokeMiterLimit
        self.trimPathStart = trimPathStart
        self.trimPathEnd = trimPathEnd
        self.trimPathOffset = trimPathOffset
    }
}

/// A `<clip-path>` element in a VectorDrawable.
public struct VectorClipPath: Sendable {
    public var name: String?
    public var pathData: String

    public init(name: String? = nil, pathData: String = "") {
        self.name = name
        self.pathData = pathData
    }
}

// MARK: - XML Parser

private final class VectorDrawableXMLParser: NSObject, XMLParserDelegate {
    private var rootDrawable: VectorDrawable?
    private var groupStack: [VectorGroup] = []
    private var rootElements: [VectorElement] = []
    private var currentPath: VectorPath?
    private var currentGradient: VectorGradient?
    private var isInsideFillColorAttr: Bool = false
    private var parseError: Error?

    func parse(data: Data) throws -> VectorDrawable {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        guard parser.parse(), let root = rootDrawable else {
            let detail = parseError?.localizedDescription
                ?? parser.parserError?.localizedDescription
                ?? "Could not parse VectorDrawable XML"
            throw AdaptiveIconError.invalidXML(detail)
        }
        var finalDrawable = root
        finalDrawable.elements = rootElements
        return finalDrawable
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String] = [:]
    ) {
        switch elementName {
        case "vector":
            let width = parseDimension(attributes["android:width"]) ?? 108
            let height = parseDimension(attributes["android:height"]) ?? 108
            let vpWidth = Double(attributes["android:viewportWidth"] ?? "") ?? width
            let vpHeight = Double(attributes["android:viewportHeight"] ?? "") ?? height
            let alpha = Double(attributes["android:alpha"] ?? "") ?? 1.0
            let tint = attributes["android:tint"]
            let tintMode = attributes["android:tintMode"]

            rootDrawable = VectorDrawable(
                width: width,
                height: height,
                viewportWidth: vpWidth,
                viewportHeight: vpHeight,
                alpha: alpha,
                tint: tint,
                tintMode: tintMode,
                elements: []
            )

        case "group":
            let group = VectorGroup(
                name: attributes["android:name"],
                rotation: Double(attributes["android:rotation"] ?? "") ?? 0,
                pivotX: Double(attributes["android:pivotX"] ?? "") ?? 0,
                pivotY: Double(attributes["android:pivotY"] ?? "") ?? 0,
                scaleX: Double(attributes["android:scaleX"] ?? "") ?? 1,
                scaleY: Double(attributes["android:scaleY"] ?? "") ?? 1,
                translateX: Double(attributes["android:translateX"] ?? "") ?? 0,
                translateY: Double(attributes["android:translateY"] ?? "") ?? 0,
                children: []
            )
            groupStack.append(group)

        case "path":
            currentPath = VectorPath(
                name: attributes["android:name"],
                pathData: attributes["android:pathData"] ?? "",
                fillColor: attributes["android:fillColor"],
                fillAlpha: Double(attributes["android:fillAlpha"] ?? "") ?? 1.0,
                fillType: (attributes["android:fillType"] == "evenOdd") ? .evenOdd : .nonZero,
                strokeColor: attributes["android:strokeColor"],
                strokeWidth: Double(attributes["android:strokeWidth"] ?? "") ?? 0,
                strokeAlpha: Double(attributes["android:strokeAlpha"] ?? "") ?? 1.0,
                strokeLineCap: parseLineCap(attributes["android:strokeLineCap"]),
                strokeLineJoin: parseLineJoin(attributes["android:strokeLineJoin"]),
                strokeMiterLimit: Double(attributes["android:strokeMiterLimit"] ?? "") ?? 4.0,
                trimPathStart: Double(attributes["android:trimPathStart"] ?? "") ?? 0,
                trimPathEnd: Double(attributes["android:trimPathEnd"] ?? "") ?? 1,
                trimPathOffset: Double(attributes["android:trimPathOffset"] ?? "") ?? 0
            )

        case "aapt:attr":
            if attributes["name"] == "android:fillColor" {
                isInsideFillColorAttr = true
            }

        case "gradient":
            let typeStr = attributes["android:type"] ?? "linear"
            let type: VectorGradient.GradientType
            switch typeStr {
            case "radial": type = .radial
            case "sweep": type = .sweep
            default: type = .linear
            }

            currentGradient = VectorGradient(
                type: type,
                startX: Double(attributes["android:startX"] ?? "") ?? 0,
                startY: Double(attributes["android:startY"] ?? "") ?? 0,
                endX: Double(attributes["android:endX"] ?? "") ?? 0,
                endY: Double(attributes["android:endY"] ?? "") ?? 0,
                centerX: Double(attributes["android:centerX"] ?? "") ?? 0,
                centerY: Double(attributes["android:centerY"] ?? "") ?? 0,
                gradientRadius: Double(attributes["android:gradientRadius"] ?? "") ?? 0,
                startColor: attributes["android:startColor"],
                endColor: attributes["android:endColor"],
                centerColor: attributes["android:centerColor"],
                stops: []
            )

        case "item":
            if var grad = currentGradient,
               let color = attributes["android:color"] {
                let offset = Double(attributes["android:offset"] ?? "") ?? 0
                grad.stops.append(VectorGradient.Stop(offset: offset, color: color))
                currentGradient = grad
            }

        case "clip-path":
            let clip = VectorClipPath(
                name: attributes["android:name"],
                pathData: attributes["android:pathData"] ?? ""
            )
            addElement(.clipPath(clip))

        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        switch elementName {
        case "group":
            if !groupStack.isEmpty {
                let finishedGroup = groupStack.removeLast()
                addElement(.group(finishedGroup))
            }
        case "gradient":
            if isInsideFillColorAttr || currentPath != nil {
                currentPath?.fillGradient = currentGradient
                currentGradient = nil
            }
        case "aapt:attr":
            isInsideFillColorAttr = false
        case "path":
            if let path = currentPath {
                addElement(.path(path))
                currentPath = nil
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }

    private func addElement(_ element: VectorElement) {
        if !groupStack.isEmpty {
            groupStack[groupStack.count - 1].children.append(element)
        } else {
            rootElements.append(element)
        }
    }

    private func parseDimension(_ str: String?) -> Double? {
        guard var s = str?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        for unit in ["dp", "dip", "sp", "px", "in", "mm", "pt"] {
            if s.hasSuffix(unit) {
                s.removeLast(unit.count)
                break
            }
        }
        return Double(s)
    }

    private func parseLineCap(_ str: String?) -> CGLineCap {
        switch str {
        case "round": .round
        case "square": .square
        default: .butt
        }
    }

    private func parseLineJoin(_ str: String?) -> CGLineJoin {
        switch str {
        case "round": .round
        case "bevel": .bevel
        default: .miter
        }
    }
}
