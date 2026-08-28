import CoreGraphics
import Foundation

/// Parses SVG `pathData` strings (as used in Android Vector Drawables) into `CGPath` objects.
public enum SVGPathParser {

    /// Parse an SVG path data string into a `CGPath`.
    ///
    /// Supports all standard SVG path commands:
    /// - `M` / `m`: Moveto
    /// - `L` / `l`: Lineto
    /// - `H` / `h`: Horizontal lineto
    /// - `V` / `v`: Vertical lineto
    /// - `C` / `c`: Cubic Bézier curve
    /// - `S` / `s`: Smooth cubic Bézier curve
    /// - `Q` / `q`: Quadratic Bézier curve
    /// - `T` / `t`: Smooth quadratic Bézier curve
    /// - `A` / `a`: Elliptical arc
    /// - `Z` / `z`: Close path
    public static func parse(_ pathData: String) -> CGPath {
        let path = CGMutablePath()
        let tokens = tokenize(pathData)
        var tokenIndex = 0

        var currentPoint = CGPoint.zero
        var subpathStart = CGPoint.zero
        var lastCubicControlPoint: CGPoint?
        var lastQuadControlPoint: CGPoint?

        func hasNextNumber() -> Bool {
            guard tokenIndex < tokens.count else { return false }
            if case .number = tokens[tokenIndex] { return true }
            return false
        }

        func readNumber() -> CGFloat? {
            guard tokenIndex < tokens.count else { return nil }
            if case .number(let value) = tokens[tokenIndex] {
                tokenIndex += 1
                return CGFloat(value)
            }
            return nil
        }

        while tokenIndex < tokens.count {
            guard case .command(let cmd) = tokens[tokenIndex] else {
                tokenIndex += 1
                continue
            }
            tokenIndex += 1

            let isRelative = cmd.isLowercase
            let commandChar = Character(cmd.uppercased())

            switch commandChar {
            case "M":
                var isFirst = true
                while hasNextNumber() {
                    guard let x = readNumber(), let y = readNumber() else { break }
                    let pt: CGPoint
                    if isRelative && !isFirst {
                        pt = CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                    } else if isRelative && isFirst {
                        pt = CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                    } else {
                        pt = CGPoint(x: x, y: y)
                    }

                    if isFirst {
                        path.move(to: pt)
                        subpathStart = pt
                        isFirst = false
                    } else {
                        // Implicit lineto for subsequent coordinates
                        path.addLine(to: pt)
                    }
                    currentPoint = pt
                    lastCubicControlPoint = nil
                    lastQuadControlPoint = nil
                }

            case "L":
                while hasNextNumber() {
                    guard let x = readNumber(), let y = readNumber() else { break }
                    let pt = isRelative
                        ? CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                        : CGPoint(x: x, y: y)
                    path.addLine(to: pt)
                    currentPoint = pt
                    lastCubicControlPoint = nil
                    lastQuadControlPoint = nil
                }

            case "H":
                while hasNextNumber() {
                    guard let x = readNumber() else { break }
                    let pt = isRelative
                        ? CGPoint(x: currentPoint.x + x, y: currentPoint.y)
                        : CGPoint(x: x, y: currentPoint.y)
                    path.addLine(to: pt)
                    currentPoint = pt
                    lastCubicControlPoint = nil
                    lastQuadControlPoint = nil
                }

            case "V":
                while hasNextNumber() {
                    guard let y = readNumber() else { break }
                    let pt = isRelative
                        ? CGPoint(x: currentPoint.x, y: currentPoint.y + y)
                        : CGPoint(x: currentPoint.x, y: y)
                    path.addLine(to: pt)
                    currentPoint = pt
                    lastCubicControlPoint = nil
                    lastQuadControlPoint = nil
                }

            case "C":
                while hasNextNumber() {
                    guard let x1 = readNumber(), let y1 = readNumber(),
                          let x2 = readNumber(), let y2 = readNumber(),
                          let x = readNumber(), let y = readNumber() else { break }

                    let cp1 = isRelative
                        ? CGPoint(x: currentPoint.x + x1, y: currentPoint.y + y1)
                        : CGPoint(x: x1, y: y1)
                    let cp2 = isRelative
                        ? CGPoint(x: currentPoint.x + x2, y: currentPoint.y + y2)
                        : CGPoint(x: x2, y: y2)
                    let endPt = isRelative
                        ? CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                        : CGPoint(x: x, y: y)

                    path.addCurve(to: endPt, control1: cp1, control2: cp2)
                    currentPoint = endPt
                    lastCubicControlPoint = cp2
                    lastQuadControlPoint = nil
                }

            case "S":
                while hasNextNumber() {
                    guard let x2 = readNumber(), let y2 = readNumber(),
                          let x = readNumber(), let y = readNumber() else { break }

                    let cp1: CGPoint
                    if let prevCP = lastCubicControlPoint {
                        cp1 = CGPoint(x: 2 * currentPoint.x - prevCP.x, y: 2 * currentPoint.y - prevCP.y)
                    } else {
                        cp1 = currentPoint
                    }

                    let cp2 = isRelative
                        ? CGPoint(x: currentPoint.x + x2, y: currentPoint.y + y2)
                        : CGPoint(x: x2, y: y2)
                    let endPt = isRelative
                        ? CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                        : CGPoint(x: x, y: y)

                    path.addCurve(to: endPt, control1: cp1, control2: cp2)
                    currentPoint = endPt
                    lastCubicControlPoint = cp2
                    lastQuadControlPoint = nil
                }

            case "Q":
                while hasNextNumber() {
                    guard let x1 = readNumber(), let y1 = readNumber(),
                          let x = readNumber(), let y = readNumber() else { break }

                    let cp = isRelative
                        ? CGPoint(x: currentPoint.x + x1, y: currentPoint.y + y1)
                        : CGPoint(x: x1, y: y1)
                    let endPt = isRelative
                        ? CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                        : CGPoint(x: x, y: y)

                    path.addQuadCurve(to: endPt, control: cp)
                    currentPoint = endPt
                    lastQuadControlPoint = cp
                    lastCubicControlPoint = nil
                }

            case "T":
                while hasNextNumber() {
                    guard let x = readNumber(), let y = readNumber() else { break }

                    let cp: CGPoint
                    if let prevCP = lastQuadControlPoint {
                        cp = CGPoint(x: 2 * currentPoint.x - prevCP.x, y: 2 * currentPoint.y - prevCP.y)
                    } else {
                        cp = currentPoint
                    }

                    let endPt = isRelative
                        ? CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                        : CGPoint(x: x, y: y)

                    path.addQuadCurve(to: endPt, control: cp)
                    currentPoint = endPt
                    lastQuadControlPoint = cp
                    lastCubicControlPoint = nil
                }

            case "A":
                while hasNextNumber() {
                    guard let rx = readNumber(), let ry = readNumber(),
                          let rot = readNumber(),
                          let largeArc = readNumber(), let sweep = readNumber(),
                          let x = readNumber(), let y = readNumber() else { break }

                    let endPt = isRelative
                        ? CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                        : CGPoint(x: x, y: y)

                    addArc(
                        to: path,
                        from: currentPoint,
                        to: endPt,
                        rx: abs(rx),
                        ry: abs(ry),
                        xAxisRotation: rot,
                        largeArcFlag: largeArc != 0,
                        sweepFlag: sweep != 0
                    )

                    currentPoint = endPt
                    lastCubicControlPoint = nil
                    lastQuadControlPoint = nil
                }

            case "Z":
                path.closeSubpath()
                currentPoint = subpathStart
                lastCubicControlPoint = nil
                lastQuadControlPoint = nil

            default:
                break
            }
        }

        return path
    }

    // MARK: - Tokenizer

    private enum Token {
        case command(Character)
        case number(Double)
    }

    private static func tokenize(_ pathData: String) -> [Token] {
        var tokens: [Token] = []
        let scalars = Array(pathData.unicodeScalars)
        var i = 0

        while i < scalars.count {
            let ch = Character(scalars[i])

            // Whitespace or comma
            if ch.isWhitespace || ch == "," {
                i += 1
                continue
            }

            // Command character
            if "MmLlHhVvCcSsQqTtAaZz".contains(ch) {
                tokens.append(.command(ch))
                i += 1
                continue
            }

            // Number: optional sign, digits, optional decimal point and digits, optional exponent
            if ch == "+" || ch == "-" || ch == "." || ch.isNumber {
                var numStr = ""
                var hasDecimal = false
                var hasExponent = false

                while i < scalars.count {
                    let c = Character(scalars[i])

                    if c == "+" || c == "-" {
                        if numStr.isEmpty || numStr.hasSuffix("e") || numStr.hasSuffix("E") {
                            numStr.append(c)
                            i += 1
                        } else {
                            // Start of next number
                            break
                        }
                    } else if c == "." {
                        if !hasDecimal && !hasExponent {
                            hasDecimal = true
                            numStr.append(c)
                            i += 1
                        } else {
                            // Second decimal point marks the start of next number (e.g. "1.2.3")
                            break
                        }
                    } else if c == "e" || c == "E" {
                        if !hasExponent && !numStr.isEmpty {
                            hasExponent = true
                            numStr.append(c)
                            i += 1
                        } else {
                            break
                        }
                    } else if c.isNumber {
                        numStr.append(c)
                        i += 1
                    } else {
                        break
                    }
                }

                if let val = Double(numStr) {
                    tokens.append(.number(val))
                }
                continue
            }

            i += 1
        }

        return tokens
    }

    // MARK: - Arc conversion (SVG W3C Spec F.6)

    private static func addArc(
        to path: CGMutablePath,
        from p0: CGPoint,
        to p1: CGPoint,
        rx: CGFloat,
        ry: CGFloat,
        xAxisRotation: CGFloat,
        largeArcFlag: Bool,
        sweepFlag: Bool
    ) {
        if p0.x == p1.x && p0.y == p1.y { return }
        if rx == 0 || ry == 0 {
            path.addLine(to: p1)
            return
        }

        let phi = xAxisRotation * .pi / 180.0
        let cosPhi = cos(phi)
        let sinPhi = sin(phi)

        // Step 1: Compute (x1', y1')
        let dx = (p0.x - p1.x) / 2.0
        let dy = (p0.y - p1.y) / 2.0
        let x1p = cosPhi * dx + sinPhi * dy
        let y1p = -sinPhi * dx + cosPhi * dy

        var rx = rx
        var ry = ry
        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1.0 {
            let sqrtLambda = sqrt(lambda)
            rx *= sqrtLambda
            ry *= sqrtLambda
        }

        // Step 2: Compute (cx', cy')
        let rxSq = rx * rx
        let rySq = ry * ry
        let x1pSq = x1p * x1p
        let y1pSq = y1p * y1p

        var sq = (rxSq * rySq - rxSq * y1pSq - rySq * x1pSq) / (rxSq * y1pSq + rySq * x1pSq)
        if sq < 0 { sq = 0 }
        let sign: CGFloat = (largeArcFlag == sweepFlag) ? -1.0 : 1.0
        let coef = sign * sqrt(sq)
        let cxp = coef * (rx * y1p / ry)
        let cyp = coef * -(ry * x1p / rx)

        // Step 3: Compute (cx, cy) from (cx', cy')
        let cx = cosPhi * cxp - sinPhi * cyp + (p0.x + p1.x) / 2.0
        let cy = sinPhi * cxp + cosPhi * cyp + (p0.y + p1.y) / 2.0

        // Step 4: Compute theta1 and dtheta
        func vectorAngle(ux: CGFloat, uy: CGFloat, vx: CGFloat, vy: CGFloat) -> CGFloat {
            let dot = ux * vx + uy * vy
            let len = sqrt(ux * ux + uy * uy) * sqrt(vx * vx + vy * vy)
            guard len > 0 else { return 0 }
            var cosVal = dot / len
            if cosVal < -1.0 { cosVal = -1.0 }
            if cosVal > 1.0 { cosVal = 1.0 }
            let angle = acos(cosVal)
            return (ux * vy - uy * vx < 0) ? -angle : angle
        }

        let ux = (x1p - cxp) / rx
        let uy = (y1p - cyp) / ry
        let vx = (-x1p - cxp) / rx
        let vy = (-y1p - cyp) / ry

        let theta1 = vectorAngle(ux: 1.0, uy: 0.0, vx: ux, vy: uy)
        var dtheta = vectorAngle(ux: ux, uy: uy, vx: vx, vy: vy)

        if !sweepFlag && dtheta > 0 {
            dtheta -= 2.0 * .pi
        } else if sweepFlag && dtheta < 0 {
            dtheta += 2.0 * .pi
        }

        // Step 5: Approximate arc with cubic Bézier segments (segments <= 90 deg)
        let numSegments = max(1, Int(ceil(abs(dtheta) / (.pi / 2.0))))
        let segmentDelta = dtheta / CGFloat(numSegments)

        for seg in 0..<numSegments {
            let t1 = theta1 + CGFloat(seg) * segmentDelta
            let t2 = t1 + segmentDelta

            let alpha = sin(segmentDelta) * (sqrt(4.0 + 3.0 * pow(tan(segmentDelta / 2.0), 2.0)) - 1.0) / 3.0

            let cosT1 = cos(t1), sinT1 = sin(t1)
            let cosT2 = cos(t2), sinT2 = sin(t2)

            let cp1 = CGPoint(
                x: cosPhi * (rx * (cosT1 - alpha * sinT1)) - sinPhi * (ry * (sinT1 + alpha * cosT1)) + cx,
                y: sinPhi * (rx * (cosT1 - alpha * sinT1)) + cosPhi * (ry * (sinT1 + alpha * cosT1)) + cy
            )

            let cp2 = CGPoint(
                x: cosPhi * (rx * (cosT2 + alpha * sinT2)) - sinPhi * (ry * (sinT2 - alpha * cosT2)) + cx,
                y: sinPhi * (rx * (cosT2 + alpha * sinT2)) + cosPhi * (ry * (sinT2 - alpha * cosT2)) + cy
            )

            let ep2 = CGPoint(
                x: cosPhi * (rx * cosT2) - sinPhi * (ry * sinT2) + cx,
                y: sinPhi * (rx * cosT2) + cosPhi * (ry * sinT2) + cy
            )

            path.addCurve(to: ep2, control1: cp1, control2: cp2)
        }
    }
}
