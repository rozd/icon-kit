/// Appearance variant for specialization targeting.
public enum Appearance: String, Codable, Hashable, Sendable {
    case light
    case dark
    case tinted
}

/// Device idiom for specialization targeting.
public enum Idiom: String, Codable, Hashable, Sendable {
    case square
    case macOS
    case iOS
    case watchOS
    case visionOS
}

/// A value specialized for a specific appearance and/or device idiom.
///
/// When both `appearance` and `idiom` are nil, this is a default specialization
/// that overrides the base value when no more specific match is found.
public struct Specialization<Value: Codable & Hashable & Sendable>: Codable, Hashable, Sendable {

    public var appearance: Appearance?
    public var idiom: Idiom?
    public var value: Value

    public init(appearance: Appearance? = nil, idiom: Idiom? = nil, value: Value) {
        self.appearance = appearance
        self.idiom = idiom
        self.value = value
    }
}

/// Resolves the best matching value from a base value and an array of specializations.
///
/// Resolution priority (highest to lowest):
/// 1. Exact match — both appearance and idiom match
/// 2. Appearance-only match — appearance matches, specialization's idiom is nil
/// 3. Idiom-only match — idiom matches, specialization's appearance is nil
/// 4. Default specialization — both appearance and idiom are nil
/// 5. Base value — no specialization matched
public func resolveSpecialization<Value>(
    base: Value,
    specializations: [Specialization<Value>],
    appearance: Appearance? = nil,
    idiom: Idiom? = nil
) -> Value {
    // 1. Exact match
    if let match = specializations.first(where: {
        $0.appearance == appearance && $0.idiom == idiom && ($0.appearance != nil || $0.idiom != nil)
    }) {
        return match.value
    }

    // 2. Appearance-only match
    if let appearance, let match = specializations.first(where: {
        $0.appearance == appearance && $0.idiom == nil
    }) {
        return match.value
    }

    // 3. Idiom-only match
    if let idiom, let match = specializations.first(where: {
        $0.idiom == idiom && $0.appearance == nil
    }) {
        return match.value
    }

    // 4. Default specialization (both nil)
    if let match = specializations.first(where: {
        $0.appearance == nil && $0.idiom == nil
    }) {
        return match.value
    }

    // 5. Base value
    return base
}
