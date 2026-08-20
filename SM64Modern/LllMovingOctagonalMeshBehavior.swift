import Foundation

struct SM64LllMovingOctagonalMeshInput: Equatable, Sendable {
    let mode: UInt8
    let action: Int32
    let timer: Int32
    let sequenceIndex: Int32
    let positionX: Float
    let positionY: Float
    let positionZ: Float
    let homeY: Float
    let forwardVelocity: Float
    let moveYaw: Int32
    let verticalAngle: Int32
    let rotationAngle: Int32
    let baseOffset: Float
    let marioOnPlatform: Bool
}

struct SM64LllMovingOctagonalMeshOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let sequenceIndex: Int32
    let positionX: Float
    let positionY: Float
    let positionZ: Float
    let forwardVelocity: Float
    let moveYaw: Int32
    let velocityX: Float
    let velocityZ: Float
    let verticalAngle: Int32
    let rotationAngle: Int32
    let baseOffset: Float
    let reachedVerticalEndpoint: Bool
}

/// Value counterpart of `bhv_lll_moving_octagonal_mesh_platform_loop`.
enum SM64LllMovingOctagonalMeshBehavior {
    private struct Step {
        let command: Int32
        let duration: Int32
        let yaw: Int32
        let targetSpeed: Float
        let speedStep: Float
        let nextIndex: Int32
    }

    private static let mode0: [Int32: Step] = [
        0: Step(command: 2, duration: 30, yaw: 0x4000, targetSpeed: 0, speedStep: 0, nextIndex: 4),
        4: Step(command: 1, duration: 220, yaw: 0, targetSpeed: 9, speedStep: 0.3, nextIndex: 8),
        8: Step(command: 1, duration: 30, yaw: 0, targetSpeed: 0, speedStep: -0.3, nextIndex: 12),
        12: Step(command: 2, duration: 30, yaw: -0x4000, targetSpeed: 0, speedStep: 0, nextIndex: 16),
        16: Step(command: 1, duration: 220, yaw: 0, targetSpeed: 9, speedStep: 0.3, nextIndex: 20),
        20: Step(command: 1, duration: 30, yaw: 0, targetSpeed: 0, speedStep: -0.3, nextIndex: 24),
        24: Step(command: 3, duration: 0, yaw: 0, targetSpeed: 0, speedStep: 0, nextIndex: 0)
    ]

    private static let mode1: [Int32: Step] = [
        0: Step(command: 4, duration: 0, yaw: 0, targetSpeed: 0, speedStep: 0, nextIndex: 4),
        4: Step(command: 1, duration: 475, yaw: 0, targetSpeed: 9, speedStep: 0.3, nextIndex: 8),
        8: Step(command: 1, duration: 30, yaw: 0, targetSpeed: 0, speedStep: -0.3, nextIndex: 12),
        12: Step(command: 2, duration: 30, yaw: 0x8000, targetSpeed: 0, speedStep: 0, nextIndex: 16),
        16: Step(command: 1, duration: 475, yaw: 0, targetSpeed: 9, speedStep: 0.3, nextIndex: 20),
        20: Step(command: 1, duration: 30, yaw: 0, targetSpeed: 0, speedStep: -0.3, nextIndex: 24),
        24: Step(command: 3, duration: 0, yaw: 0, targetSpeed: 0, speedStep: 0, nextIndex: 0)
    ]

    static func update(_ input: SM64LllMovingOctagonalMeshInput)
        -> SM64LllMovingOctagonalMeshOutput
    {
        var action = input.action
        var timer = input.timer
        var sequenceIndex = input.sequenceIndex
        var forwardVelocity = input.forwardVelocity
        var moveYaw = input.moveYaw
        let steps = input.mode == 0 ? mode0 : mode1

        if input.action == 0 {
            sequenceIndex = 0
            action = 1
        } else if let step = steps[sequenceIndex] {
            switch step.command {
            case 4:
                moveYaw = step.yaw
                forwardVelocity = step.targetSpeed
                if input.marioOnPlatform {
                    sequenceIndex = step.nextIndex
                    timer = 0
                }
            case 2:
                moveYaw = step.yaw
                forwardVelocity = step.targetSpeed
                if input.timer > step.duration {
                    sequenceIndex = step.nextIndex
                    timer = 0
                }
            case 1:
                forwardVelocity += step.speedStep
                if step.speedStep >= 0 {
                    if forwardVelocity > step.targetSpeed { forwardVelocity = step.targetSpeed }
                } else if forwardVelocity < step.targetSpeed {
                    forwardVelocity = step.targetSpeed
                }
                if input.timer > step.duration {
                    sequenceIndex = step.nextIndex
                    timer = 0
                }
            case 3:
                forwardVelocity = 0
                sequenceIndex = 0
            default:
                break
            }
        }

        let velocityX = SM64DeterministicPrimitives.cFloatMultiply(
            forwardVelocity,
            SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: moveYaw))
        )
        let velocityZ = SM64DeterministicPrimitives.cFloatMultiply(
            forwardVelocity,
            SM64CanonicalTrig.coss(Int16(truncatingIfNeeded: moveYaw))
        )
        var verticalAngle = input.verticalAngle
        if input.marioOnPlatform { verticalAngle = min(verticalAngle &+ 0x400, 0x4000) }
        else { verticalAngle = max(verticalAngle &- 0x400, 0) }
        let verticalOffset = SM64DeterministicPrimitives.cFloatMultiply(
            SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: verticalAngle)),
            -80
        )
        var rotationAngle = input.rotationAngle
        var baseOffset = input.baseOffset
        let reachedEndpoint = verticalAngle == 0 || verticalAngle == 0x4000
        if reachedEndpoint {
            rotationAngle &+= 0x800
            baseOffset -= SM64DeterministicPrimitives.cFloatMultiply(
                SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: rotationAngle)),
                2
            )
        }
        return SM64LllMovingOctagonalMeshOutput(
            action: action,
            timer: timer,
            sequenceIndex: sequenceIndex,
            positionX: input.positionX + velocityX,
            positionY: input.homeY + baseOffset + verticalOffset,
            positionZ: input.positionZ + velocityZ,
            forwardVelocity: forwardVelocity,
            moveYaw: moveYaw,
            velocityX: velocityX,
            velocityZ: velocityZ,
            verticalAngle: verticalAngle,
            rotationAngle: rotationAngle,
            baseOffset: baseOffset,
            reachedVerticalEndpoint: reachedEndpoint
        )
    }
}
