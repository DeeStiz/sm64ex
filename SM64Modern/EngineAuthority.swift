import Foundation

enum SM64ModernEngineAuthority: String, CaseIterable, Sendable {
    case swift
    case cCompatibility = "c"

    var displayName: String {
        switch self {
        case .swift:
            "Swift Engine"
        case .cCompatibility:
            "C Compatibility"
        }
    }

    var menuDescription: String {
        switch self {
        case .swift:
            "Swift-owned engine (default)"
        case .cCompatibility:
            "Portable C engine compatibility mode"
        }
    }
}

enum SM64ModernEngineAuthoritySource: String, Sendable {
    case defaultValue = "default"
    case persistedSetting = "persisted"
    case environmentOverride = "environment"
}

struct SM64ModernEngineAuthoritySelection: Sendable {
    let authority: SM64ModernEngineAuthority
    let source: SM64ModernEngineAuthoritySource
    let invalidValue: String?

    /// Persisted settings are recoverable: the resolver falls back to Swift
    /// and the application rewrites the setting. Environment overrides are a
    /// test/configuration contract, so an invalid value must fail launch.
    var isValid: Bool {
        invalidValue == nil || source == .persistedSetting
    }

    var requiresLaunchFailure: Bool {
        invalidValue != nil && source == .environmentOverride
    }

    func requiresRestart(comparedTo activeAuthority: SM64ModernEngineAuthority) -> Bool {
        authority != activeAuthority
    }

    static func requiresRestart(
        selectedAuthority: SM64ModernEngineAuthority,
        activeAuthority: SM64ModernEngineAuthority
    ) -> Bool {
        selectedAuthority != activeAuthority
    }
}

enum SM64ModernEngineAuthorityStore {
    static let environmentKey = "SM64_MODERN_ENGINE"
    static let defaultsKey = "SM64Modern.EngineAuthority"

    static func resolve(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        persistedValue: String? = UserDefaults.standard.string(forKey: defaultsKey)
    ) -> SM64ModernEngineAuthoritySelection {
        if let override = environment[environmentKey] {
            guard let authority = SM64ModernEngineAuthority(rawValue: override) else {
                return SM64ModernEngineAuthoritySelection(
                    authority: .swift,
                    source: .environmentOverride,
                    invalidValue: override
                )
            }
            return SM64ModernEngineAuthoritySelection(
                authority: authority,
                source: .environmentOverride,
                invalidValue: nil
            )
        }

        if let persistedValue {
            guard let authority = SM64ModernEngineAuthority(rawValue: persistedValue) else {
                return SM64ModernEngineAuthoritySelection(
                    authority: .swift,
                    source: .persistedSetting,
                    invalidValue: persistedValue
                )
            }
            return SM64ModernEngineAuthoritySelection(
                authority: authority,
                source: .persistedSetting,
                invalidValue: nil
            )
        }

        return SM64ModernEngineAuthoritySelection(
            authority: .swift,
            source: .defaultValue,
            invalidValue: nil
        )
    }

    static func persist(
        _ authority: SM64ModernEngineAuthority,
        defaults: UserDefaults = .standard
    ) {
        defaults.set(authority.rawValue, forKey: defaultsKey)
    }
}
