import Foundation

enum SM64StarSpawnAction: Int32, Equatable, Sendable {
    case intro = 0
    case rise = 1
    case fall = 2
    case landed = 3
}

enum SM64StarSpawnSound: Int32, Equatable, Sendable {
    case none = -1
    case environmentStar = 0
    case starAppears = 1
}

struct SM64StarSpawnCoordinatesInput: Equatable, Sendable {
    let starCollected: Bool
    let action: SM64StarSpawnAction
    let timer: Int32
    let position: SM64ObjectVector3
    let homePosition: SM64ObjectVector3
    let moveYaw: Int32
    let faceYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let starSpawnBaseY: Float
    let interactionStatus: Int32
}

struct SM64StarSpawnCoordinatesOutput: Equatable, Sendable {
    let starCollected: Bool
    let model: SM64CollectStarModel
    let action: SM64StarSpawnAction
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let faceYaw: Int32
    let forwardVelocity: Float
    let velocityY: Float
    let starSpawnBaseY: Float
    let spawnSparkle: Bool
    let soundIntent: SM64StarSpawnSound
    let becomeTangible: Bool
    let clearTimeStop: Bool
    let shouldDelete: Bool
    let clearInteraction: Bool
}

/// Value counterpart of `bhv_star_spawn_init` and `bhv_star_spawn_loop`.
enum SM64StarSpawnCoordinatesBehavior {
    static func initialState(
        starCollected: Bool,
        position: SM64ObjectVector3,
        homePosition: SM64ObjectVector3
    ) -> SM64StarSpawnCoordinatesOutput {
        let deltaX = homePosition.x - position.x
        let deltaZ = homePosition.z - position.z
        let planarDistance = (deltaX * deltaX + deltaZ * deltaZ).squareRoot()
        return .init(
            starCollected: starCollected,
            model: starCollected ? .transparentStar : .star,
            action: .intro,
            position: position,
            moveYaw: Int32(SM64CanonicalTrig.atan2s(y: deltaZ, x: deltaX)),
            faceYaw: 0,
            forwardVelocity: planarDistance / 30,
            velocityY: (homePosition.y - position.y) / 30,
            starSpawnBaseY: position.y,
            spawnSparkle: false,
            soundIntent: .none,
            becomeTangible: false,
            clearTimeStop: false,
            shouldDelete: false,
            clearInteraction: false
        )
    }

    static func update(_ input: SM64StarSpawnCoordinatesInput) -> SM64StarSpawnCoordinatesOutput {
        var action = input.action
        var position = input.position
        var faceYaw = input.faceYaw
        var forwardVelocity = input.forwardVelocity
        var velocityY = input.velocityY
        var starSpawnBaseY = input.starSpawnBaseY
        var spawnSparkle = false
        var soundIntent: SM64StarSpawnSound = .none
        var becomeTangible = false
        var clearTimeStop = false
        var shouldDelete = false
        var clearInteraction = false

        switch input.action {
        case .intro:
            faceYaw &+= 0x1000
            if input.timer > 20 { action = .rise }

        case .rise:
            position.x += forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
            position.z += forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
            starSpawnBaseY += velocityY
            let phase = Int32((Int64(input.timer) * 0x8000) / 30)
            position.y = starSpawnBaseY + 400 * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: phase))
            faceYaw &+= 0x1000
            spawnSparkle = true
            soundIntent = .environmentStar
            if input.timer == 30 {
                action = .fall
                forwardVelocity = 0
            }

        case .fall:
            velocityY = input.timer < 20 ? Float(20 - input.timer) : -10
            spawnSparkle = true
            soundIntent = .environmentStar
            position.x += forwardVelocity * SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw))
            position.z += forwardVelocity * SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw))
            position.y += velocityY
            faceYaw = faceYaw &- input.timer &* 0x10 &+ 0x1000
            if position.y < input.homePosition.y {
                position.y = input.homePosition.y
                action = .landed
                becomeTangible = true
                soundIntent = .starAppears
            }

        case .landed:
            faceYaw &+= 0x800
            clearTimeStop = input.timer == 20
            if input.interactionStatus != 0 {
                shouldDelete = true
                clearInteraction = true
            }
        }

        return .init(
            starCollected: input.starCollected,
            model: input.starCollected ? .transparentStar : .star,
            action: action,
            position: position,
            moveYaw: input.moveYaw,
            faceYaw: faceYaw,
            forwardVelocity: forwardVelocity,
            velocityY: velocityY,
            starSpawnBaseY: starSpawnBaseY,
            spawnSparkle: spawnSparkle,
            soundIntent: soundIntent,
            becomeTangible: becomeTangible,
            clearTimeStop: clearTimeStop,
            shouldDelete: shouldDelete,
            clearInteraction: clearInteraction
        )
    }
}
