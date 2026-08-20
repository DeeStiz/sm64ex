import Foundation

/// Copied, fixed-width inputs for `bhv_mad_piano_update`. The owner bridge
/// supplies collision/movement facts; the reducer never receives a C object
/// pointer or mutates an object record directly.
struct SM64MadPianoInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let homePosition: SM64ObjectVector3
    let moveYaw: Int32
    let angleToMario: Int32
    let distanceToMario: Float
    let marioForwardVelocity: Float
    let animationNearEnd: Bool
    let floorAndWallsUpdated: Bool

    init(
        action: Int32 = SM64MadPianoBehavior.waitAction,
        timer: Int32 = 0,
        position: SM64ObjectVector3 = .zero,
        homePosition: SM64ObjectVector3 = .zero,
        moveYaw: Int32 = 0,
        angleToMario: Int32 = 0,
        distanceToMario: Float = 10_000,
        marioForwardVelocity: Float = 0,
        animationNearEnd: Bool = false,
        floorAndWallsUpdated: Bool = false
    ) {
        self.action = action
        self.timer = timer
        self.position = position
        self.homePosition = homePosition
        self.moveYaw = moveYaw
        self.angleToMario = angleToMario
        self.distanceToMario = distanceToMario
        self.marioForwardVelocity = marioForwardVelocity
        self.animationNearEnd = animationNearEnd
        self.floorAndWallsUpdated = floorAndWallsUpdated
    }
}

struct SM64MadPianoEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    /// The source pushes Mario from the cylinder on every wait frame.
    static let pushMario = Self(rawValue: 1 << 0)
    /// `SOUND_OBJ_MAD_PIANO_CHOMPING` is emitted by the attack animation.
    static let chompSound = Self(rawValue: 1 << 1)
    /// The attack hitbox is active through `obj_check_attacks`.
    static let attackHitbox = Self(rawValue: 1 << 2)
    static let tangible = Self(rawValue: 1 << 3)
    static let intangible = Self(rawValue: 1 << 4)
    static let clampedToHome = Self(rawValue: 1 << 5)
}

struct SM64MadPianoOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let forwardVelocity: Float
    let moveYaw: Int32
    let faceYaw: Int32
    let animation: Int32
    let tangible: Bool
    let effects: SM64MadPianoEffect
}

/// Value counterpart of the compact Mad Piano action machine in
/// `src/game/behaviors/mad_piano.inc.c`.
enum SM64MadPianoBehavior {
    static let waitAction: Int32 = 0 // MAD_PIANO_ACT_WAIT
    static let attackAction: Int32 = 1 // MAD_PIANO_ACT_ATTACK
    static let triggerDistance: Float = 500
    static let homeRadius: Float = 400
    static let yawIncrement: Int32 = 400

    static func update(_ input: SM64MadPianoInput) -> SM64MadPianoOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var position = input.position
        var forwardVelocity: Float = 0
        var moveYaw = input.moveYaw
        var animation: Int32 = 0
        var tangible = false
        var effects: SM64MadPianoEffect = [.pushMario]

        switch input.action {
        case waitAction:
            animation = 0
            if input.distanceToMario < triggerDistance {
                if input.timer > 20 && input.marioForwardVelocity > 10 {
                    action = attackAction
                    tangible = true
                    effects.formUnion([.tangible, .attackHitbox])
                }
            } else {
                // Matches the source's explicit idle timer reset when Mario
                // leaves the 500-unit activation cylinder.
                timer = 0
            }

        case attackAction:
            animation = 1
            tangible = true
            effects.formUnion([.tangible, .attackHitbox, .chompSound])

            if input.distanceToMario < triggerDistance {
                // The source keeps the attack alive while Mario is close.
                timer = 0
            }

            if input.timer > 80 && input.animationNearEnd {
                action = waitAction
                forwardVelocity = 0
                tangible = false
                effects.subtract([.tangible, .attackHitbox])
                effects.insert(.intangible)
            } else {
                let dx = input.position.x - input.homePosition.x
                let dz = input.position.z - input.homePosition.z
                let distance = (dx * dx + dz * dz).squareRoot()
                if distance > homeRadius {
                    let scale = homeRadius / distance
                    position.x = input.homePosition.x + dx * scale
                    position.z = input.homePosition.z + dz * scale
                    effects.insert(.clampedToHome)
                }

                moveYaw = approachAngle(
                    current: input.moveYaw,
                    target: input.angleToMario,
                    increment: yawIncrement
                )
                forwardVelocity = 5
            }

        default:
            // Invalid action values use the C-safe wait fallback. The owner
            // remains responsible for rejecting the invalid record if policy
            // requires a hard fallback to the legacy callback.
            action = waitAction
            animation = 0
            timer = 0
            effects.formUnion([.intangible, .pushMario])
        }

        return SM64MadPianoOutput(
            action: action,
            timer: timer,
            position: position,
            forwardVelocity: forwardVelocity,
            moveYaw: moveYaw,
            faceYaw: moveYaw &- 0x4000,
            animation: animation,
            tangible: tangible,
            effects: effects
        )
    }

    private static func approachAngle(current: Int32, target: Int32, increment: Int32) -> Int32 {
        let delta = Int32(Int16(truncatingIfNeeded: target &- current))
        if delta > increment { return current &+ increment }
        if delta < -increment { return current &- increment }
        return target
    }
}
