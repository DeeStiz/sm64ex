import Foundation

enum SM64PiranhaPlantBubbleAction: UInt8, Equatable, Sendable {
    case idle = 0
    case growShrink = 1
    case burst = 2
}

struct SM64PiranhaPlantBubbleInput: Equatable, Sendable {
    let parentPosition: SM64ObjectVector3
    let parentYaw: Int32
    let parentSleeping: Bool
    let parentFrame: Int32
    let lastAnimationFrame: Int32
    let activeWithinRadius: Bool
    let action: SM64PiranhaPlantBubbleAction
}

struct SM64PiranhaPlantBubbleOutput: Equatable, Sendable {
    let position: SM64ObjectVector3
    let action: SM64PiranhaPlantBubbleAction
    let scale: Float
    let hidden: Bool
    let spawnWakingBubbleCount: Int32
}

/// Value counterpart of `bhv_piranha_plant_bubble_loop`.
enum SM64PiranhaPlantBubbleBehavior {
    static func update(_ input: SM64PiranhaPlantBubbleInput) -> SM64PiranhaPlantBubbleOutput {
        let yaw = Int16(truncatingIfNeeded: input.parentYaw)
        let position = SM64ObjectVector3(
            x: input.parentPosition.x + 180 * SM64CanonicalTrig.sins(yaw),
            y: input.parentPosition.y + 72,
            z: input.parentPosition.z + 180 * SM64CanonicalTrig.coss(yaw)
        )
        switch input.action {
        case .idle:
            return SM64PiranhaPlantBubbleOutput(
                position: position,
                action: input.parentSleeping ? .growShrink : .idle,
                scale: 0,
                hidden: true,
                spawnWakingBubbleCount: 0
            )
        case .growShrink:
            guard input.activeWithinRadius else {
                return SM64PiranhaPlantBubbleOutput(
                    position: position,
                    action: .growShrink,
                    scale: 0,
                    hidden: true,
                    spawnWakingBubbleCount: 0
                )
            }
            guard input.parentSleeping else {
                return SM64PiranhaPlantBubbleOutput(
                    position: position,
                    action: .burst,
                    scale: 0,
                    hidden: true,
                    spawnWakingBubbleCount: 0
                )
            }
            let last = max(1, input.lastAnimationFrame)
            let doneShrinking = Double(last) / 2 - 4
            let beginGrowing = Double(last) / 2 + 4
            let frame = Double(input.parentFrame)
            let scale: Float
            if frame < doneShrinking, doneShrinking > 0 {
                let angle = Int16(truncatingIfNeeded: Int32(frame / doneShrinking * 0x4000))
                scale = SM64CanonicalTrig.coss(angle) * 4 + 1
            } else if frame > beginGrowing {
                let angle = Int16(truncatingIfNeeded: Int32((frame - beginGrowing) / beginGrowing * 0x4000))
                scale = SM64CanonicalTrig.sins(angle) * 4 + 1
            } else {
                scale = 1
            }
            return SM64PiranhaPlantBubbleOutput(
                position: position,
                action: .growShrink,
                scale: scale,
                hidden: false,
                spawnWakingBubbleCount: 0
            )
        case .burst:
            return SM64PiranhaPlantBubbleOutput(
                position: position,
                action: .idle,
                scale: 0,
                hidden: true,
                spawnWakingBubbleCount: 15
            )
        }
    }
}
