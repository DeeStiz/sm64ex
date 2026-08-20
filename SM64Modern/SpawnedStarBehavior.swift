import Foundation

enum SM64SpawnedStarAction: Int32, Equatable, Sendable {
    case launch = 0
    case settle = 1
    case waitForCutscene = 2
    case idle = 3
}

enum SM64SpawnedStarSound: Int32, Equatable, Sendable {
    case none = -1
    case environmentStar = 0
    case powerStarJingle = 1
    case starAppears = 2
}

struct SM64SpawnedStarInput: Equatable, Sendable {
    let starCollected: Bool
    let noExit: Bool
    let action: SM64SpawnedStarAction
    let timer: Int32
    let position: SM64ObjectVector3
    let homePosition: SM64ObjectVector3
    let moveYaw: Int32
    let faceYaw: Int32
    let angleVelocityYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let interactionStatus: Int32
    let cameraClear: Bool
}

struct SM64SpawnedStarOutput: Equatable, Sendable {
    let starCollected: Bool
    let noExit: Bool
    let model: SM64CollectStarModel
    let action: SM64SpawnedStarAction
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let faceYaw: Int32
    let angleVelocityYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let gravity: Float
    let spawnSparkle: Bool
    let spawnMist: Bool
    let soundIntent: SM64SpawnedStarSound
    let becomeTangible: Bool
    let clearTimeStop: Bool
    let shouldDelete: Bool
    let clearInteraction: Bool
}

/// Value counterpart of `bhv_spawned_star_init` and `bhv_spawned_star_loop`.
enum SM64SpawnedStarBehavior {
    static func initialState(
        starCollected: Bool,
        noExit: Bool,
        position: SM64ObjectVector3,
        homePosition: SM64ObjectVector3,
        marioPosition: SM64ObjectVector3,
        moveToMario: Bool
    ) -> SM64SpawnedStarOutput {
        var home = homePosition
        var initialPosition = position
        var forwardVelocity: Float = 0
        if moveToMario {
            home = .init(x: marioPosition.x, y: marioPosition.y + 250, z: marioPosition.z)
            initialPosition.y = home.y
            let dx = home.x - initialPosition.x
            let dz = home.z - initialPosition.z
            forwardVelocity = (dx * dx + dz * dz).squareRoot() / 23
        }
        return .init(
            starCollected: starCollected,
            noExit: noExit,
            model: starCollected ? .transparentStar : .star,
            action: .launch,
            position: initialPosition,
            moveYaw: SM64CanonicalTrig.atan2s(y: home.z - initialPosition.z, x: home.x - initialPosition.x).toInt32,
            faceYaw: 0,
            angleVelocityYaw: 0x800,
            forwardVelocity: forwardVelocity,
            velocityY: 50,
            gravity: -4,
            spawnSparkle: false,
            spawnMist: true,
            soundIntent: .none,
            becomeTangible: false,
            clearTimeStop: false,
            shouldDelete: false,
            clearInteraction: false
        )
    }

    static func update(_ input: SM64SpawnedStarInput) -> SM64SpawnedStarOutput {
        var action = input.action
        var position = input.position
        var faceYaw = input.faceYaw
        var angleVelocityYaw = input.angleVelocityYaw
        var forwardVelocity = input.forwardVelocity
        var velocityY = input.velocityY
        var gravity = input.gravity
        var spawnSparkle = false
        var soundIntent: SM64SpawnedStarSound = .none
        var becomeTangible = false
        var clearTimeStop = false
        var shouldDelete = false
        var clearInteraction = false

        switch input.action {
        case .launch:
            if input.timer == 0 { soundIntent = .environmentStar }
            spawnSparkle = true
            soundIntent = .environmentStar
            velocityY += gravity
            position.x += forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
            position.z += forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
            position.y += velocityY
            if velocityY < 0 && position.y < input.homePosition.y {
                action = .settle
                forwardVelocity = 0
                velocityY = 20
                gravity = -1
                soundIntent = .powerStarJingle
            }

        case .settle:
            if velocityY < -4 { velocityY = -4 }
            if velocityY < 0 && position.y < input.homePosition.y {
                action = .waitForCutscene
                velocityY = 0
                gravity = 0
            }
            spawnSparkle = true
            position.x += forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
            position.z += forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
            position.y += velocityY

        case .waitForCutscene:
            if input.cameraClear {
                clearTimeStop = true
                action = .idle
            }

        case .idle:
            becomeTangible = true
            if angleVelocityYaw > 0x400 { angleVelocityYaw -= 0x40 }
            if input.interactionStatus != 0 {
                shouldDelete = true
                clearInteraction = true
            }
        }

        faceYaw &+= angleVelocityYaw
        return .init(
            starCollected: input.starCollected,
            noExit: input.noExit,
            model: input.starCollected ? .transparentStar : .star,
            action: action,
            position: position,
            moveYaw: input.moveYaw,
            faceYaw: faceYaw,
            angleVelocityYaw: angleVelocityYaw,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            gravity: gravity,
            spawnSparkle: spawnSparkle,
            spawnMist: false,
            soundIntent: soundIntent,
            becomeTangible: becomeTangible,
            clearTimeStop: clearTimeStop,
            shouldDelete: shouldDelete,
            clearInteraction: clearInteraction
        )
    }
}

private extension Int16 {
    var toInt32: Int32 { Int32(self) }
}
