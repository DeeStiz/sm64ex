import Foundation

struct SM64LllDrawbridgeInput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let globalTimer: UInt64
    let faceRoll: Int32
}

struct SM64LllDrawbridgeOutput: Equatable, Sendable {
    let action: Int32
    let faceRoll: Int32
    let playLowerSound: Bool
    let playRaiseSound: Bool
}

/// Value counterpart of `bhv_lll_drawbridge_loop`.
enum SM64LllDrawbridgeBehavior {
    static func update(_ input: SM64LllDrawbridgeInput) -> SM64LllDrawbridgeOutput {
        var action = input.action
        var faceRoll = Int16(truncatingIfNeeded: input.faceRoll)

        switch input.action {
        case 0:
            faceRoll = Int16(truncatingIfNeeded: Int32(faceRoll) &+ 0x100)
        case 1:
            faceRoll = Int16(truncatingIfNeeded: Int32(faceRoll) &- 0x100)
        default:
            break
        }

        var playLowerSound = false
        var playRaiseSound = false
        if faceRoll < -0x1FFD {
            faceRoll = Int16(bitPattern: 0xDFFF)
            if input.timer >= 51, input.globalTimer % 8 == 0 {
                action = 0
                playLowerSound = true
            }
        }
        if faceRoll >= 0 {
            faceRoll = 0
            if input.timer >= 51, input.globalTimer % 8 == 0 {
                action = 1
                playRaiseSound = true
            }
        }

        return SM64LllDrawbridgeOutput(
            action: action,
            faceRoll: Int32(faceRoll),
            playLowerSound: playLowerSound,
            playRaiseSound: playRaiseSound
        )
    }
}
