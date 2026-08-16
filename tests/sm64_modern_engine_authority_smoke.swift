import Foundation

@main
enum SM64ModernEngineAuthoritySmoke {
    static func main() {
        let defaultSelection = SM64ModernEngineAuthorityStore.resolve(
            environment: [:],
            persistedValue: nil
        )
        precondition(defaultSelection.authority == .swift)
        precondition(defaultSelection.source == .defaultValue)
        precondition(defaultSelection.isValid)

        let persistedSelection = SM64ModernEngineAuthorityStore.resolve(
            environment: [:],
            persistedValue: "c"
        )
        precondition(persistedSelection.authority == .cCompatibility)
        precondition(persistedSelection.source == .persistedSetting)
        precondition(persistedSelection.isValid)
        precondition(persistedSelection.requiresRestart(comparedTo: .swift))
        precondition(!persistedSelection.requiresRestart(comparedTo: .cCompatibility))

        let overrideSelection = SM64ModernEngineAuthorityStore.resolve(
            environment: [SM64ModernEngineAuthorityStore.environmentKey: "swift"],
            persistedValue: "c"
        )
        precondition(overrideSelection.authority == .swift)
        precondition(overrideSelection.source == .environmentOverride)
        precondition(overrideSelection.isValid)

        let invalidEnvironment = SM64ModernEngineAuthorityStore.resolve(
            environment: [SM64ModernEngineAuthorityStore.environmentKey: "metal"],
            persistedValue: "c"
        )
        precondition(invalidEnvironment.authority == .swift)
        precondition(invalidEnvironment.source == .environmentOverride)
        precondition(invalidEnvironment.invalidValue == "metal")
        precondition(!invalidEnvironment.isValid)

        let invalidPersisted = SM64ModernEngineAuthorityStore.resolve(
            environment: [:],
            persistedValue: "legacy"
        )
        precondition(invalidPersisted.authority == .swift)
        precondition(invalidPersisted.source == .persistedSetting)
        precondition(invalidPersisted.invalidValue == "legacy")
        precondition(invalidPersisted.isValid)
        precondition(!invalidPersisted.requiresLaunchFailure)

        let suiteName = "sm64-modern-engine-authority-\(UUID().uuidString)"
        let injectedDefaults = UserDefaults(suiteName: suiteName)!
        defer { injectedDefaults.removePersistentDomain(forName: suiteName) }
        SM64ModernEngineAuthorityStore.persist(.cCompatibility, defaults: injectedDefaults)
        let injectedSelection = SM64ModernEngineAuthorityStore.resolve(
            defaults: injectedDefaults,
            environment: [:]
        )
        precondition(injectedSelection.authority == .cCompatibility)
        precondition(injectedSelection.source == .persistedSetting)
        precondition(injectedSelection.requiresRestart(comparedTo: .swift))

        injectedDefaults.set("invalid", forKey: SM64ModernEngineAuthorityStore.defaultsKey)
        let repairedSelection = SM64ModernEngineAuthorityStore.resolve(
            defaults: injectedDefaults,
            environment: [:]
        )
        precondition(repairedSelection.authority == .swift)
        precondition(repairedSelection.invalidValue == "invalid")
        precondition(repairedSelection.isValid)

        print("SM64 Modern engine authority smoke passed")
    }
}
