import Foundation

enum SM64BowlingBallRole: UInt8, Equatable, Sendable {
    case spawner = 0
    case rolling = 1
    case free = 2
    case pit = 3
}

struct SM64BowlingBallInput: Equatable, Sendable {
    let role: SM64BowlingBallRole
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let homePosition: SM64ObjectVector3
    let moveYaw: Int32
    let targetYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let behaviorParam: Int32
    let distanceToMario: Float
    let marioY: Float
    let periodMinus1: Int32
    let maxSpawnDistance: Float
    let spawnAdmission: Bool
    let pathEnded: Bool
    let grounded: Bool
    let landed: Bool
    let floorFlat: Bool
}

struct SM64BowlingBallOutput: Equatable, Sendable {
    let role: SM64BowlingBallRole
    let action: Int32
    let timer: Int32
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let scale: Float
    let graphYOffset: Float
    let tangible: Bool
    let visible: Bool
    let spawnBall: Bool
    let shouldDelete: Bool
    let resetToHome: Bool
    let cameraShake: Bool
    let playRollSound: Bool
    let playGroundSound: Bool
}

/// Value counterpart of the generic bowling-ball spawner, rolling ball, and
/// free bowling-ball scripts. Path following is represented as a fixed-width
/// target-yaw/path-ended input so the C waypoint pointer never crosses into
/// Swift.
enum SM64BowlingBallBehavior {
    static func update(_ input: SM64BowlingBallInput) -> SM64BowlingBallOutput {
        switch input.role {
        case .spawner:
            return updateSpawner(input)
        case .rolling:
            return updateRolling(input)
        case .free:
            return updateFree(input)
        case .pit:
            return updatePit(input)
        }
    }

    private static func updateSpawner(_ input: SM64BowlingBallInput) -> SM64BowlingBallOutput {
        var timer = input.timer
        if timer == 256 { timer = 0 }
        let eligible = input.distanceToMario >= 1_000
            && input.position.y >= input.marioY
            && (timer & input.periodMinus1) == 0
            && input.distanceToMario <= input.maxSpawnDistance
        let spawn = eligible && input.spawnAdmission
        return .init(
            role: .spawner, action: input.action, timer: timer &+ 1,
            position: input.position, moveYaw: input.moveYaw,
            forwardVelocity: input.forwardVelocity, velocityY: input.velocityY,
            scale: 1, graphYOffset: 0, tangible: true, visible: true,
            spawnBall: spawn, shouldDelete: false, resetToHome: false,
            cameraShake: false, playRollSound: false, playGroundSound: false
        )
    }

    private static func updateRolling(_ input: SM64BowlingBallInput) -> SM64BowlingBallOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var position = input.position
        var yaw = input.moveYaw
        var forward = input.forwardVelocity
        var velocityY = input.velocityY
        var scale: Float = 1
        var graphYOffset: Float = 130
        var playGroundSound = false

        if input.action == 0 {
            action = 1
            timer = 0
            forward = initialForwardVelocity(for: input.behaviorParam)
            if input.behaviorParam == 4 {
                scale = 0.3
                graphYOffset = 39
            }
        } else {
            yaw = approachAngle(input.moveYaw, input.targetYaw, increment: 0x400)
            position.x += SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: yaw)) * forward
            position.z += SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: yaw)) * forward
            position.y += velocityY
            velocityY = max(velocityY - 4, -20)
            forward = min(forward, 70)
            playGroundSound = input.grounded && velocityY > 5
        }
        return .init(
            role: .rolling, action: action, timer: timer, position: position,
            moveYaw: yaw, forwardVelocity: forward, velocityY: velocityY,
            scale: scale, graphYOffset: graphYOffset, tangible: true, visible: true,
            spawnBall: false, shouldDelete: input.pathEnded, resetToHome: false,
            cameraShake: input.behaviorParam != 4, playRollSound: false,
            playGroundSound: playGroundSound
        )
    }

    private static func updateFree(_ input: SM64BowlingBallInput) -> SM64BowlingBallOutput {
        var action = input.action
        var timer = input.timer &+ 1
        var position = input.position
        var yaw = input.moveYaw
        var forward = input.forwardVelocity
        var velocityY = input.velocityY
        var tangible = false
        var visible = false
        var resetToHome = false
        var cameraShake = false
        var playRollSound = false
        var playGroundSound = false

        switch input.action {
        case 0:
            if input.distanceToMario < 3_000 {
                action = 1
                timer = 0
                tangible = true
                visible = true
            }
        case 1:
            tangible = true
            visible = true
            yaw = approachAngle(input.moveYaw, input.targetYaw, increment: 0x400)
            position.x += SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: yaw)) * forward
            position.z += SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: yaw)) * forward
            position.y += velocityY
            velocityY = max(velocityY - 4, -20)
            if forward > 10 {
                cameraShake = true
                playRollSound = true
            }
            playGroundSound = input.grounded && !input.landed
            if input.distanceToMario > 6_000 {
                action = 2
                timer = 0
                tangible = false
                visible = false
                position = input.homePosition
                forward = 0
                velocityY = 0
                resetToHome = true
            }
        case 2:
            if input.distanceToMario < 5_000 {
                action = 0
                timer = 0
            }
        default:
            action = 0
            timer = 0
        }

        return .init(
            role: .free, action: action, timer: timer, position: position,
            moveYaw: yaw, forwardVelocity: forward, velocityY: velocityY,
            scale: 1, graphYOffset: 130, tangible: tangible, visible: visible,
            spawnBall: false, shouldDelete: false, resetToHome: resetToHome,
            cameraShake: cameraShake, playRollSound: playRollSound,
            playGroundSound: playGroundSound
        )
    }

    private static func updatePit(_ input: SM64BowlingBallInput) -> SM64BowlingBallOutput {
        .init(
            role: .pit,
            action: input.action,
            timer: input.timer &+ 1,
            position: input.position,
            moveYaw: input.moveYaw,
            forwardVelocity: input.floorFlat ? 28 : input.forwardVelocity,
            velocityY: input.velocityY,
            scale: 1,
            graphYOffset: 130,
            tangible: true,
            visible: true,
            spawnBall: false,
            shouldDelete: false,
            resetToHome: false,
            cameraShake: true,
            playRollSound: true,
            playGroundSound: false
        )
    }

    private static func initialForwardVelocity(for behaviorParam: Int32) -> Float {
        switch behaviorParam {
        case 0, 2: return 20
        case 1, 4: return 10
        case 3: return 25
        default: return 20
        }
    }

    private static func approachAngle(_ value: Int32, _ target: Int32, increment: Int32) -> Int32 {
        let delta = Int16(truncatingIfNeeded: target &- value)
        if delta > Int16(increment) { return value &+ increment }
        if delta < -Int16(increment) { return value &- increment }
        return target
    }
}
