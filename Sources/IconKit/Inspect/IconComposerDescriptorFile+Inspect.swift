extension IconComposerDescriptorFile {

    /// Produce a human-readable summary of this icon bundle.
    ///
    /// - Parameter bundleName: Display name (typically the `.icon` directory's last path component).
    /// - Returns: Multi-line string describing the bundle structure.
    public func inspectSummary(bundleName: String) -> String {
        var lines: [String] = []

        lines.append(bundleName)

        // Document-level properties
        if let colorSpace = document.colorSpaceForUntaggedSVGColors {
            lines.append("  Color space for untagged SVGs: \(colorSpace)")
        }
        if let fill = document.fill {
            lines.append("  Fill: \(formatFill(fill))")
        }
        if let specs = document.fillSpecializations, !specs.isEmpty {
            lines.append("  Fill specializations:")
            lines.append(contentsOf: formatSpecializations(specs, valueFormatter: formatFill))
        }
        if let platforms = document.supportedPlatforms {
            lines.append("  Platforms: \(formatPlatforms(platforms))")
        }

        // Groups
        if document.groups.isEmpty {
            lines.append("  Groups: (none)")
        } else {
            for (index, group) in document.groups.enumerated() {
                let number = index + 1
                let label = group.name.map { "Group \(number) \"\($0)\"" } ?? "Group \(number)"
                lines.append("  \(label)")
                lines.append(contentsOf: formatGroup(group, indent: "    "))
            }
        }

        // Asset summary
        let referenced = referencedImageNames
        let missing = validateAssets()
        let presentCount = assets.count
        let missingCount = missing.count
        let unreferenced = Set(assets.keys).subtracting(referenced)

        var assetLine = "  Assets: \(presentCount) present, \(missingCount) missing"
        if !unreferenced.isEmpty {
            assetLine += ", \(unreferenced.count) unreferenced"
        }
        lines.append(assetLine)
        for name in missing.sorted() {
            lines.append("    Missing: \(name)")
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Group Formatting

private func formatGroup(_ group: IconGroup, indent: String) -> [String] {
    var lines: [String] = []

    if group.hidden == true {
        lines.append("\(indent)Hidden")
    }
    if let lighting = group.lighting {
        lines.append("\(indent)Lighting: \(lighting.rawValue)")
    }
    if let shadow = group.shadow {
        lines.append("\(indent)Shadow: \(formatShadow(shadow))")
    }
    if let translucency = group.translucency, translucency.enabled {
        lines.append("\(indent)Translucency: \(formatTranslucency(translucency))")
    }
    if let blurMaterial = group.blurMaterial {
        lines.append("\(indent)Blur material: \(formatDouble(blurMaterial))")
    }
    if let opacity = group.opacity, opacity != 1.0 {
        lines.append("\(indent)Opacity: \(formatDouble(opacity))")
    }
    if let specular = group.specular {
        lines.append("\(indent)Specular: \(specular)")
    }
    if let blendMode = group.blendMode, blendMode != .normal {
        lines.append("\(indent)Blend mode: \(blendMode.rawValue)")
    }

    // Layers
    for (index, layer) in group.layers.enumerated() {
        let number = index + 1
        let label = layer.name.map { "Layer \"\($0)\"" } ?? "Layer \(number)"
        lines.append("\(indent)\(label)")
        lines.append(contentsOf: formatLayer(layer, indent: indent + "  "))
    }

    // Group-level specializations
    lines.append(contentsOf: formatGroupSpecializations(group, indent: indent))

    return lines
}

// MARK: - Layer Formatting

private func formatLayer(_ layer: IconLayer, indent: String) -> [String] {
    var lines: [String] = []

    if let imageName = layer.imageName {
        lines.append("\(indent)Image: \(imageName)")
    }
    if let fill = layer.fill {
        lines.append("\(indent)Fill: \(formatFill(fill))")
    }
    if layer.hidden == true {
        lines.append("\(indent)Hidden")
    }
    if layer.glass == true {
        lines.append("\(indent)Glass: true")
    }
    if let opacity = layer.opacity, opacity != 1.0 {
        lines.append("\(indent)Opacity: \(formatDouble(opacity))")
    }
    if let blendMode = layer.blendMode, blendMode != .normal {
        lines.append("\(indent)Blend mode: \(blendMode.rawValue)")
    }
    if let position = layer.position, !isIdentity(position) {
        lines.append("\(indent)Position: \(formatPosition(position))")
    }

    // Layer-level specializations
    if let specs = layer.imageNameSpecializations, !specs.isEmpty {
        lines.append("\(indent)Image specializations:")
        lines.append(contentsOf: formatSpecializations(specs, indent: indent + "  ") { $0 })
    }
    if let specs = layer.fillSpecializations, !specs.isEmpty {
        lines.append("\(indent)Fill specializations:")
        lines.append(contentsOf: formatSpecializations(specs, indent: indent + "  ", valueFormatter: formatFill))
    }
    if let specs = layer.blendModeSpecializations, !specs.isEmpty {
        lines.append("\(indent)Blend mode specializations:")
        lines.append(contentsOf: formatSpecializations(specs, indent: indent + "  ") { $0.rawValue })
    }
    if let specs = layer.opacitySpecializations, !specs.isEmpty {
        lines.append("\(indent)Opacity specializations:")
        lines.append(contentsOf: formatSpecializations(specs, indent: indent + "  ", valueFormatter: formatDouble))
    }
    if let specs = layer.hiddenSpecializations, !specs.isEmpty {
        lines.append("\(indent)Hidden specializations:")
        lines.append(contentsOf: formatSpecializations(specs, indent: indent + "  ") { "\($0)" })
    }
    if let specs = layer.glassSpecializations, !specs.isEmpty {
        lines.append("\(indent)Glass specializations:")
        lines.append(contentsOf: formatSpecializations(specs, indent: indent + "  ") { "\($0)" })
    }
    if let specs = layer.positionSpecializations, !specs.isEmpty {
        lines.append("\(indent)Position specializations:")
        lines.append(contentsOf: formatSpecializations(specs, indent: indent + "  ", valueFormatter: formatPosition))
    }

    return lines
}

// MARK: - Group Specializations

private func formatGroupSpecializations(_ group: IconGroup, indent: String) -> [String] {
    var lines: [String] = []

    if let specs = group.hiddenSpecializations, !specs.isEmpty {
        lines.append("\(indent)Hidden specializations:")
        lines.append(contentsOf: formatSpecializations(specs, indent: indent + "  ") { "\($0)" })
    }
    if let specs = group.shadowSpecializations, !specs.isEmpty {
        lines.append("\(indent)Shadow specializations:")
        lines.append(contentsOf: formatSpecializations(specs, indent: indent + "  ", valueFormatter: formatShadow))
    }
    if let specs = group.translucencySpecializations, !specs.isEmpty {
        lines.append("\(indent)Translucency specializations:")
        lines.append(contentsOf: formatSpecializations(specs, indent: indent + "  ", valueFormatter: formatTranslucency))
    }
    if let specs = group.opacitySpecializations, !specs.isEmpty {
        lines.append("\(indent)Opacity specializations:")
        lines.append(contentsOf: formatSpecializations(specs, indent: indent + "  ", valueFormatter: formatDouble))
    }
    if let specs = group.specularSpecializations, !specs.isEmpty {
        lines.append("\(indent)Specular specializations:")
        lines.append(contentsOf: formatSpecializations(specs, indent: indent + "  ") { "\($0)" })
    }
    if let specs = group.blendModeSpecializations, !specs.isEmpty {
        lines.append("\(indent)Blend mode specializations:")
        lines.append(contentsOf: formatSpecializations(specs, indent: indent + "  ") { $0.rawValue })
    }
    if let specs = group.positionSpecializations, !specs.isEmpty {
        lines.append("\(indent)Position specializations:")
        lines.append(contentsOf: formatSpecializations(specs, indent: indent + "  ", valueFormatter: formatPosition))
    }

    return lines
}

// MARK: - Value Formatters

private func formatFill(_ fill: IconFill) -> String {
    switch fill {
    case .automatic:
        "automatic"
    case .systemLight:
        "system-light"
    case .systemDark:
        "system-dark"
    case .solid(let color):
        "solid \(color.stringRepresentation)"
    case .automaticGradient(let color):
        "automatic-gradient \(color.stringRepresentation)"
    }
}

private func formatPosition(_ pos: IconPosition) -> String {
    "scale \(formatDouble(pos.scale)), translate (\(formatDouble(pos.translationX)), \(formatDouble(pos.translationY)))"
}

private func formatShadow(_ shadow: IconShadow) -> String {
    "\(shadow.kind.rawValue) (opacity: \(formatDouble(shadow.opacity)))"
}

private func formatTranslucency(_ t: IconTranslucency) -> String {
    "enabled (value: \(formatDouble(t.value)))"
}

private func formatPlatforms(_ sp: SupportedPlatforms) -> String {
    var parts: [String] = []
    if let circles = sp.circles {
        parts.append("circles [\(circles.joined(separator: ", "))]")
    }
    if let squares = sp.squares {
        switch squares {
        case .shared:
            parts.append("squares shared")
        case .platforms(let platforms):
            parts.append("squares [\(platforms.joined(separator: ", "))]")
        }
    }
    return parts.joined(separator: ", ")
}

// MARK: - Specialization Formatting

private func formatSpecializationQualifier(appearance: Appearance?, idiom: Idiom?) -> String {
    switch (appearance, idiom) {
    case let (a?, i?):
        "[\(a.rawValue), \(i.rawValue)]"
    case let (a?, nil):
        "[\(a.rawValue)]"
    case let (nil, i?):
        "[\(i.rawValue)]"
    case (nil, nil):
        "[default]"
    }
}

private func formatSpecializations<V>(
    _ specs: [Specialization<V>],
    indent: String = "      ",
    valueFormatter: (V) -> String
) -> [String] {
    specs.map { spec in
        let qualifier = formatSpecializationQualifier(appearance: spec.appearance, idiom: spec.idiom)
        return "\(indent)\(qualifier) \(valueFormatter(spec.value))"
    }
}

// MARK: - Helpers

private func isIdentity(_ pos: IconPosition) -> Bool {
    pos.scale == 1.0 && pos.translationX == 0.0 && pos.translationY == 0.0
}

private func formatDouble(_ value: Double) -> String {
    value.truncatingRemainder(dividingBy: 1) == 0
        ? String(format: "%.1f", value)
        : "\(value)"
}
