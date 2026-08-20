import Foundation

struct SM64MarioQuicksandInput: Equatable, Sendable {
    let floorType: UInt32
    let ridingShell: Bool
    let quicksandDepth: Float
    let sinkingSpeed: Float
}

struct SM64MarioQuicksandResult: Equatable, Sendable {
    let quicksandDepth: Float
    let action: UInt32?
    let actionArgument: UInt32
    let updateSoundCamera: Bool
}

/// Value counterpart of `mario_update_quicksand`; C retains sound/camera and
/// action installation effects.
enum SM64MarioQuicksand {
    private static let shallow: UInt32 = 0x0021
    private static let deep: UInt32 = 0x0022
    private static let instant: UInt32 = 0x0023
    private static let deepMoving: UInt32 = 0x0024
    private static let shallowMoving: UInt32 = 0x0025
    private static let moving: UInt32 = 0x0027
    private static let instantMoving: UInt32 = 0x002D
    private static let quicksandDeath: UInt32 = 0x0002_1312

    static func update(_ input: SM64MarioQuicksandInput) -> SM64MarioQuicksandResult? {
        guard input.quicksandDepth.isFinite, input.sinkingSpeed.isFinite else { return nil }
        if input.ridingShell {
            return SM64MarioQuicksandResult(
                quicksandDepth: 0, action: nil, actionArgument: 0,
                updateSoundCamera: false
            )
        }

        var depth = max(input.quicksandDepth, 1.1)
        var action: UInt32?
        var updateSoundCamera = false
        switch input.floorType {
        case shallow:
            depth += input.sinkingSpeed
            depth = min(depth, 10)
        case shallowMoving:
            depth += input.sinkingSpeed
            depth = min(depth, 25)
        case moving, 0x0026:
            depth += input.sinkingSpeed
            depth = min(depth, 60)
        case deep, deepMoving:
            depth += input.sinkingSpeed
            if depth >= 160 {
                action = quicksandDeath
                updateSoundCamera = true
            }
        case instant, instantMoving:
            action = quicksandDeath
            updateSoundCamera = true
        default:
            depth = 0
        }

        return SM64MarioQuicksandResult(
            quicksandDepth: depth,
            action: action,
            actionArgument: 0,
            updateSoundCamera: updateSoundCamera
        )
    }
}
