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

        print("SM64 Modern engine authority smoke passed")
    }
}
