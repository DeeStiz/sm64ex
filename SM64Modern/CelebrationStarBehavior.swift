import Foundation

enum SM64CelebrationStarVariant: UInt8, Equatable, Sendable {
    case star = 0
    case bowserKey = 1
}

enum SM64CelebrationStarAction: Int32, Equatable, Sendable {
    case spinAroundMario = 0
    case faceCamera = 1
}

struct SM64CelebrationStarInput: Equatable, Sendable {
    let variant: SM64CelebrationStarVariant
    let action: SM64CelebrationStarAction
    let timer: Int32
    let position: SM64ObjectVector3
    let homePosition: SM64ObjectVector3
    let moveYaw: Int32
    let faceYaw: Int32
    let facePitch: Int32
    let faceRoll: Int32
    let diameter: Float
    let scale: Float
    let marioYaw: Int32
}

struct SM64CelebrationStarOutput: Equatable, Sendable {
    let variant: SM64CelebrationStarVariant
    let action: SM64CelebrationStarAction
    let position: SM64ObjectVector3
    let moveYaw: Int32
    let faceYaw: Int32
    let facePitch: Int32
    let faceRoll: Int32
    let diameter: Float
    let scale: Float
    let graphYOffset: Float
    let spawnSparkle: Bool
    let shouldDeactivate: Bool
}

/// Value counterpart of `bhv_celebration_star_init` and
/// `bhv_celebration_star_loop`.
enum SM64CelebrationStarBehavior {
    static func initialState(
        variant: SM64CelebrationStarVariant,
        marioPosition: SM64ObjectVector3,
        marioYaw: Int32
    ) -> SM64CelebrationStarOutput {
        let scale: Float = variant == .bowserKey ? 0.1 : 0.4
        let faceRoll: Int32 = variant == .bowserKey ? 49_152 : 0
        return SM64CelebrationStarOutput(
            variant: variant,
            action: .spinAroundMario,
            position: SM64ObjectVector3(x: marioPosition.x, y: marioPosition.y + 30, z: marioPosition.z),
            moveYaw: marioYaw &+ 0x8000,
            faceYaw: 0,
            facePitch: 0,
            faceRoll: faceRoll,
            diameter: 100,
            scale: scale,
            graphYOffset: 0,
            spawnSparkle: false,
            shouldDeactivate: false
        )
    }

    static func update(_ input: SM64CelebrationStarInput) -> SM64CelebrationStarOutput {
        switch input.action {
        case .spinAroundMario:
            let radius = input.diameter / 2
            var position = input.position
            position.x = input.homePosition.x + SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: input.moveYaw)) * radius
            position.z = input.homePosition.z + SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: input.moveYaw)) * radius
            position.y += 5

            var action = input.action
            if input.timer == 40 { action = .faceCamera }
            let diameter = input.timer < 35 ? input.diameter + 1 : input.diameter - 20
            return SM64CelebrationStarOutput(
                variant: input.variant,
                action: action,
                position: position,
                moveYaw: input.moveYaw &+ 0x2000,
                faceYaw: input.faceYaw &+ 0x1000,
                facePitch: input.facePitch,
                faceRoll: input.faceRoll,
                diameter: diameter,
                scale: input.scale,
                graphYOffset: 0,
                spawnSparkle: input.timer < 35,
                shouldDeactivate: false
            )

        case .faceCamera:
            var scale = input.scale
            var faceYaw = input.faceYaw
            if input.timer < 10 {
                scale = input.variant == .bowserKey
                    ? Float(input.timer) / 30
                    : Float(input.timer) / 10
                faceYaw &+= 0x1000
            } else {
                faceYaw = input.marioYaw
            }
            return SM64CelebrationStarOutput(
                variant: input.variant,
                action: .faceCamera,
                position: input.position,
                moveYaw: input.moveYaw,
                faceYaw: faceYaw,
                facePitch: input.facePitch,
                faceRoll: input.faceRoll,
                diameter: input.diameter,
                scale: scale,
                graphYOffset: 0,
                spawnSparkle: false,
                shouldDeactivate: input.timer == 59
            )
        }
    }
}
