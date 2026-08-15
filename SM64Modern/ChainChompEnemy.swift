import Foundation

enum SM64ChainChompAction: UInt8, Equatable, Sendable {
    case uninitialized = 0
    case move = 1
    case unloadChain = 2
}

enum SM64ChainChompSubAction: UInt8, Equatable, Sendable {
    case turn = 0
    case lunge = 1
}

enum SM64ChainChompReleaseStatus: UInt8, Equatable, Sendable {
    case notReleased = 0
    case triggerCutscene = 1
    case released = 2
}

struct SM64ChainChompHitbox: Equatable, Sendable {
    let interactType: UInt32
    let damageOrCoinValue: Int16
    let radius: Float
    let height: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float

    static let standard = Self(
        // INTERACT_MR_BLIZZARD.
        interactType: 1 << 21,
        damageOrCoinValue: 3,
        radius: 80,
        height: 160,
        hurtboxRadius: 80,
        hurtboxHeight: 160
    )
}

struct SM64ChainChompSegment: Equatable, Sendable {
    var x: Float = 0
    var y: Float = 0
    var z: Float = 0
}

struct SM64ChainChompState: Equatable, Sendable {
    let hitbox: SM64ChainChompHitbox

    var action: SM64ChainChompAction = .uninitialized
    var subAction: SM64ChainChompSubAction = .turn
    var releaseStatus: SM64ChainChompReleaseStatus = .notReleased
    var homeX: Float
    var homeY: Float
    var homeZ: Float
    var positionX: Float
    var positionY: Float
    var positionZ: Float
    var pivotX: Float
    var pivotY: Float
    var pivotZ: Float
    var moveYaw: Int16 = 0
    var facePitch: Int16 = 0
    var forwardVelocity: Float = 0
    var velocityY: Float = 0
    var gravity: Float = -4
    var maxDistFromPivotPerPart: Float = 150
    var maxDistBetweenParts: Float = 150
    var distanceToPivot: Float = 0
    var targetPitch: Int16 = 0
    var restrictedByChain = false
    var elasticVelocity: Float = 0
    var hitGate = false
    var numLunges: UInt8 = 0
    var hidden = true
    var tangible = true
    var markedForDeletion = false
    var segments: [SM64ChainChompSegment] = Array(repeating: SM64ChainChompSegment(), count: 5)
    var timer: UInt32 = 0

    init(homeX: Float = 0, homeY: Float = 0, homeZ: Float = 0, moveYaw: Int16 = 0) {
        self.hitbox = .standard
        self.homeX = homeX
        self.homeY = homeY
        self.homeZ = homeZ
        self.positionX = homeX
        self.positionY = homeY
        self.positionZ = homeZ
        self.pivotX = homeX
        self.pivotY = homeY
        self.pivotZ = homeZ
        self.moveYaw = moveYaw
    }
}

struct SM64ChainChompTickInput: Equatable, Sendable {
    var distanceToMario: Float
    var angleToMario: Int16
    var onGround: Bool
    var animationAtFrame: Bool
    var attacked: Bool
    var hitWall: Bool
    var globalTimer: UInt32
    var releaseStatus: SM64ChainChompReleaseStatus

    init(
        distanceToMario: Float = 10_000,
        angleToMario: Int16 = 0,
        onGround: Bool = true,
        animationAtFrame: Bool = false,
        attacked: Bool = false,
        hitWall: Bool = false,
        globalTimer: UInt32 = 0,
        releaseStatus: SM64ChainChompReleaseStatus = .notReleased
    ) {
        self.distanceToMario = distanceToMario
        self.angleToMario = angleToMario
        self.onGround = onGround
        self.animationAtFrame = animationAtFrame
        self.attacked = attacked
        self.hitWall = hitWall
        self.globalTimer = globalTimer
        self.releaseStatus = releaseStatus
    }
}

struct SM64ChainChompEffect: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    init(rawValue: UInt32) { self.rawValue = rawValue }

    static let animate = Self(rawValue: 1 << 0)
    static let allocateChain = Self(rawValue: 1 << 1)
    static let turn = Self(rawValue: 1 << 2)
    static let lunge = Self(rawValue: 1 << 3)
    static let attackStretch = Self(rawValue: 1 << 4)
    static let restrict = Self(rawValue: 1 << 5)
    static let release = Self(rawValue: 1 << 6)
    static let gateHit = Self(rawValue: 1 << 7)
    static let unload = Self(rawValue: 1 << 8)
    static let markForDeletion = Self(rawValue: 1 << 9)
}

struct SM64ChainChompTickResult: Equatable, Sendable {
    let state: SM64ChainChompState
    let effects: SM64ChainChompEffect
}

enum SM64ChainChompKernel {
    static func tick(_ input: SM64ChainChompTickInput, state: inout SM64ChainChompState) -> SM64ChainChompTickResult {
        var effects: SM64ChainChompEffect = [.animate]

        if state.action == .uninitialized {
            guard input.distanceToMario < 3_000 else {
                incrementTimer(&state)
                return SM64ChainChompTickResult(state: state, effects: effects)
            }
            state.positionX = state.homeX
            state.positionY = state.homeY
            state.positionZ = state.homeZ
            state.pivotX = state.homeX
            state.pivotY = state.homeY
            state.pivotZ = state.homeZ
            state.maxDistFromPivotPerPart = 150
            state.maxDistBetweenParts = 150
            state.hidden = false
            state.action = .move
            effects.insert(.allocateChain)
        }

        if state.action == .unloadChain {
            state.hidden = true
            state.forwardVelocity = 0
            state.velocityY = 0
            effects.insert(.unload)
            if state.releaseStatus != .notReleased {
                state.markedForDeletion = true
                effects.insert(.markForDeletion)
            }
            incrementTimer(&state)
            return SM64ChainChompTickResult(state: state, effects: effects)
        }

        if state.releaseStatus == .notReleased && input.distanceToMario > 4_000 {
            state.action = .unloadChain
            state.forwardVelocity = 0
            state.velocityY = 0
            effects.insert(.unload)
            incrementTimer(&state)
            return SM64ChainChompTickResult(state: state, effects: effects)
        }

        if input.releaseStatus == .triggerCutscene, input.onGround {
            state.releaseStatus = .released
            state.subAction = .lunge
            state.timer = 0
            effects.insert(.release)
        }

        switch state.subAction {
        case .turn:
            turn(input: input, state: &state, effects: &effects)
        case .lunge:
            lunge(input: input, state: &state, effects: &effects)
        }

        advance(&state)
        updateSegments(state: &state, effects: &effects)

        if input.attacked {
            state.subAction = .lunge
            state.maxDistFromPivotPerPart = 180
            state.forwardVelocity = 0
            state.velocityY = 300
            state.gravity = -4
            state.targetPitch = -0x3000
            effects.insert(.attackStretch)
        }
        if input.hitWall && state.releaseStatus != .notReleased {
            state.hitGate = true
            effects.insert(.gateHit)
        }

        incrementTimer(&state)
        return SM64ChainChompTickResult(state: state, effects: effects)
    }

    private static func turn(
        input: SM64ChainChompTickInput,
        state: inout SM64ChainChompState,
        effects: inout SM64ChainChompEffect
    ) {
        state.gravity = -4
        restoreNormalLengths(&state)
        state.facePitch = approachAngle(current: state.facePitch, target: 0, increment: 0x100)
        guard input.onGround else {
            state.moveYaw = approachAngle(current: state.moveYaw, target: input.angleToMario, increment: 0x190)
            state.timer = 0
            effects.insert(.turn)
            return
        }

        state.moveYaw = approachAngle(current: state.moveYaw, target: input.angleToMario, increment: 0x400)
        if absAngleDiff(input.angleToMario, state.moveYaw) < 0x800 {
            if state.timer > 30 {
                if input.animationAtFrame {
                    if state.timer > 40 {
                        state.subAction = .lunge
                        state.maxDistFromPivotPerPart = 180
                        state.forwardVelocity = 140
                        state.velocityY = 20
                        state.gravity = 0
                        state.targetPitch = pitchFromVelocity(forwardVelocity: state.forwardVelocity, velocityY: state.velocityY)
                        effects.insert(.lunge)
                    }
                } else {
                    state.timer &-= 1
                }
            } else {
                state.forwardVelocity = 0
            }
        } else {
            state.forwardVelocity = 10
            state.velocityY = 20
        }
        effects.insert(.turn)
    }

    private static func lunge(
        input: SM64ChainChompTickInput,
        state: inout SM64ChainChompState,
        effects: inout SM64ChainChompEffect
    ) {
        state.facePitch = approachAngle(current: state.facePitch, target: state.targetPitch, increment: 0x400)
        if state.forwardVelocity != 0 {
            if state.restrictedByChain {
                state.forwardVelocity = 0
                state.velocityY = 0
                state.elasticVelocity = 30
                effects.insert(.restrict)
            }
            var value = 900 - state.distanceToPivot
            if value > 220 { value = 220 }
            state.maxDistBetweenParts = value / 220 * state.maxDistFromPivotPerPart
            state.timer = 0
        } else {
            let yawToPivot = SM64CanonicalTrig.atan2s(y: state.segments[0].z, x: state.segments[0].x)
            state.moveYaw = approachAngle(current: state.moveYaw, target: yawToPivot, increment: 0x1000)
            if state.elasticVelocity != 0 {
                state.elasticVelocity = approach(state.elasticVelocity, target: 0, step: 0.8)
            } else {
                state.subAction = .turn
            }
            state.maxDistBetweenParts = input.globalTimer & 1 == 0 ? state.elasticVelocity : -state.elasticVelocity
        }
        effects.insert(.lunge)
    }

    private static func updateSegments(state: inout SM64ChainChompState, effects: inout SM64ChainChompEffect) {
        state.segments[0] = SM64ChainChompSegment(
            x: state.positionX - state.pivotX,
            y: state.positionY - state.pivotY,
            z: state.positionZ - state.pivotZ
        )
        state.distanceToPivot = length(state.segments[0])
        let maxDistance = state.maxDistFromPivotPerPart * 5
        if state.distanceToPivot > maxDistance, maxDistance > 0 {
            let ratio = maxDistance / state.distanceToPivot
            state.segments[0].x *= ratio
            state.segments[0].y *= ratio
            state.segments[0].z *= ratio
            state.distanceToPivot = maxDistance
            if state.releaseStatus == .notReleased {
                state.positionX = state.pivotX + state.segments[0].x
                state.positionY = state.pivotY + state.segments[0].y
                state.positionZ = state.pivotZ + state.segments[0].z
                state.restrictedByChain = true
                effects.insert(.restrict)
            } else {
                state.pivotX = state.positionX - state.segments[0].x
                state.pivotY = state.positionY - state.segments[0].y
                state.pivotZ = state.positionZ - state.segments[0].z
            }
        } else {
            state.restrictedByChain = false
        }

        let segmentVelocityY = state.velocityY < 0 ? state.velocityY : -20
        for index in 1...4 {
            var segment = state.segments[index]
            let previous = state.segments[index - 1]
            segment.y += segmentVelocityY
            if segment.y < 0 { segment.y = 0 }
            var dx = segment.x - previous.x
            var dy = segment.y - previous.y
            var dz = segment.z - previous.z
            var offset = (dx * dx + dy * dy + dz * dz).squareRoot()
            if offset > state.maxDistBetweenParts, offset > 0 {
                let ratio = state.maxDistBetweenParts / offset
                dx *= ratio; dy *= ratio; dz *= ratio
            }
            var x = previous.x + dx
            var y = previous.y + dy
            var z = previous.z + dz
            offset = (x * x + y * y + z * z).squareRoot()
            let maxTotalOffset = state.maxDistFromPivotPerPart * Float(5 - index)
            if offset > maxTotalOffset, offset > 0 {
                let ratio = maxTotalOffset / offset
                x *= ratio; y *= ratio; z *= ratio
            }
            segment.x = x; segment.y = y; segment.z = z
            state.segments[index] = segment
        }
    }

    private static func restoreNormalLengths(_ state: inout SM64ChainChompState) {
        state.maxDistFromPivotPerPart = approach(state.maxDistFromPivotPerPart, target: 150, step: 4)
        state.maxDistBetweenParts = state.maxDistFromPivotPerPart
    }

    private static func advance(_ state: inout SM64ChainChompState) {
        state.positionX += SM64CanonicalTrig.sins(state.moveYaw) * state.forwardVelocity
        state.positionY += state.velocityY
        state.positionZ += SM64CanonicalTrig.coss(state.moveYaw) * state.forwardVelocity
        if state.gravity != 0 { state.velocityY += state.gravity }
    }

    private static func pitchFromVelocity(forwardVelocity: Float, velocityY: Float) -> Int16 {
        SM64CanonicalTrig.atan2s(y: velocityY, x: forwardVelocity)
    }

    private static func length(_ segment: SM64ChainChompSegment) -> Float {
        (segment.x * segment.x + segment.y * segment.y + segment.z * segment.z).squareRoot()
    }

    private static func approach(_ current: Float, target: Float, step: Float) -> Float {
        if current < target { return min(target, current + step) }
        if current > target { return max(target, current - step) }
        return current
    }

    private static func absAngleDiff(_ lhs: Int16, _ rhs: Int16) -> Int32 {
        let distance = abs(Int32(lhs) - Int32(rhs))
        return min(distance, 0x1_0000 - distance)
    }

    private static func approachAngle(current: Int16, target: Int16, increment: Int16) -> Int16 {
        let distance = Int32(target) - Int32(current)
        if distance > Int32(increment) { return current &+ increment }
        if distance < -Int32(increment) { return current &- increment }
        return target
    }

    private static func incrementTimer(_ state: inout SM64ChainChompState) {
        if state.timer < 0x3FFF_FFFF { state.timer &+= 1 }
    }
}
