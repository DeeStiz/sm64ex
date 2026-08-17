import Foundation

/// Immutable Swift representation of the legacy `struct CheatList`.
/// Configuration parsing/persistence and live consumers stay separate so a
/// cheat cannot become active merely because a malformed file was repaired.
struct SM64CheatState: Equatable, Sendable {
    var enabled: Bool
    var moonJump: Bool
    var godMode: Bool
    var infiniteLives: Bool
    var superSpeed: Bool
    var responsive: Bool
    var exitAnywhere: Bool
    var hugeMario: Bool
    var tinyMario: Bool

    static let disabled = Self(
        enabled: false,
        moonJump: false,
        godMode: false,
        infiniteLives: false,
        superSpeed: false,
        responsive: false,
        exitAnywhere: false,
        hugeMario: false,
        tinyMario: false
    )

    init(
        enabled: Bool,
        moonJump: Bool,
        godMode: Bool,
        infiniteLives: Bool,
        superSpeed: Bool,
        responsive: Bool,
        exitAnywhere: Bool,
        hugeMario: Bool,
        tinyMario: Bool
    ) {
        self.enabled = enabled
        self.moonJump = moonJump
        self.godMode = godMode
        self.infiniteLives = infiniteLives
        self.superSpeed = superSpeed
        self.responsive = responsive
        self.exitAnywhere = exitAnywhere
        self.hugeMario = hugeMario
        self.tinyMario = tinyMario
    }

    init(configuration: SM64ModernConfiguration.Cheats) {
        self.init(
            enabled: configuration.enabled,
            moonJump: configuration.moonJump,
            godMode: configuration.godMode,
            infiniteLives: configuration.infiniteLives,
            superSpeed: configuration.superSpeed,
            responsive: configuration.responsive,
            exitAnywhere: configuration.exitAnywhere,
            hugeMario: configuration.hugeMario,
            tinyMario: configuration.tinyMario
        )
    }

    /// Builds the subset carried by the live Mario ground-speed ABI. The
    /// remaining flags stay false until their own consumer seams migrate.
    init(legacyEnabled: Bool, responsive: Bool) {
        self.init(
            enabled: legacyEnabled,
            moonJump: false,
            godMode: false,
            infiniteLives: false,
            superSpeed: false,
            responsive: responsive,
            exitAnywhere: false,
            hugeMario: false,
            tinyMario: false
        )
    }
}

struct SM64CheatActionResult: Equatable, Sendable {
    let health: UInt16
    let lives: UInt8
    let forwardVelocity: Float
}

/// Value-only counterparts for every legacy cheat consumer currently present
/// in C. This is a compatibility boundary, not an authority cutover: callers
/// must explicitly pass the state selected by the active engine owner.
enum SM64CheatPolicy {
    static func moonJumpVelocity(
        currentVelocity: Float,
        lTriggerDown: Bool,
        state: SM64CheatState
    ) -> Float {
        guard state.enabled, state.moonJump, lTriggerDown else {
            return currentVelocity
        }
        return 25
    }

    static func applyMarioAction(
        health: UInt16,
        lives: UInt8,
        forwardVelocity: Float,
        state: SM64CheatState
    ) -> SM64CheatActionResult {
        guard state.enabled else {
            return SM64CheatActionResult(
                health: health, lives: lives, forwardVelocity: forwardVelocity
            )
        }
        let nextHealth = state.godMode ? 0x0880 : health
        let nextLives: UInt8
        if state.infiniteLives, lives < 99 {
            nextLives = lives &+ 1
        } else {
            nextLives = lives
        }
        let nextForwardVelocity = state.superSpeed && forwardVelocity > 0
            ? forwardVelocity + 100
            : forwardVelocity
        return SM64CheatActionResult(
            health: nextHealth,
            lives: nextLives,
            forwardVelocity: nextForwardVelocity
        )
    }

    static func modelScale(for state: SM64CheatState) -> Float {
        guard state.enabled else { return 1 }
        if state.hugeMario { return 2.5 }
        if state.tinyMario { return 0.2 }
        return 1
    }

    static func canExitCourse(
        actionAllowsPauseExit: Bool,
        state: SM64CheatState
    ) -> Bool {
        actionAllowsPauseExit || (state.enabled && state.exitAnywhere)
    }

    static func responsiveMovementEnabled(for state: SM64CheatState) -> Bool {
        state.enabled && state.responsive
    }
}
