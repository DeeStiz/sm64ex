struct SM64CheatState {
    let enabled: Bool
    let responsive: Bool

    init(legacyEnabled: Bool, responsive: Bool) {
        self.enabled = legacyEnabled
        self.responsive = responsive
    }
}

enum SM64CheatPolicy {
    static func responsiveMovementEnabled(for state: SM64CheatState) -> Bool {
        state.enabled && state.responsive
    }
}
