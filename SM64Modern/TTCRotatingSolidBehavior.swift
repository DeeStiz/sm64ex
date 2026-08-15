import Foundation

struct SM64TTCRotatingSolidInitialization: Equatable, Sendable {
    let collisionModelIndex: UInt8
    let numberOfSides: Int32
    let rotationDelay: Int32
}

struct SM64TTCRotatingSolidInput: Equatable, Sendable {
    let speedSetting: Int32
    let timer: Int32
    let rotationDelay: Int32
    let soundTimer: Int32
    let verticalVelocity: Float
    let positionY: Float
    let homeY: Float
    let numberOfTurns: Int32
    let numberOfSides: Int32
    let faceRoll: Int16
    let randomRotationDelay: Int32
}

struct SM64TTCRotatingSolidOutput: Equatable, Sendable {
    let timer: Int32
    let rotationDelay: Int32
    let soundTimer: Int32
    let verticalVelocity: Float
    let positionY: Float
    let numberOfTurns: Int32
    let faceRoll: Int16
    let angleVelocityRoll: Int16
    let playedAlertSound: Bool
    let playedClickSound: Bool
}

/// Value counterpart of `bhv_ttc_rotating_solid_init` and
/// `bhv_ttc_rotating_solid_update`.
enum SM64TTCRotatingSolidBehavior {
    private static let initialDelays: [Int32] = [120, 40, 0, 0]

    static func initialize(behaviorByte: UInt8, speedSetting: Int32)
        -> SM64TTCRotatingSolidInitialization
    {
        SM64TTCRotatingSolidInitialization(
            collisionModelIndex: behaviorByte,
            numberOfSides: behaviorByte == 0 ? 4 : 3,
            rotationDelay: initialDelays[Int(speedSetting)]
        )
    }

    static func update(_ input: SM64TTCRotatingSolidInput) -> SM64TTCRotatingSolidOutput {
        var timer = input.timer
        var rotationDelay = input.rotationDelay
        var soundTimer = input.soundTimer
        var verticalVelocity = input.verticalVelocity
        var positionY = input.positionY
        var numberOfTurns = input.numberOfTurns
        var faceRoll = input.faceRoll
        var angleVelocityRoll: Int16 = 0
        var playedAlertSound = false
        var playedClickSound = false

        if input.speedSetting != 3 && input.timer > input.rotationDelay {
            if soundTimer != 0 {
                soundTimer -= 1
                if soundTimer == 0 {
                    playedAlertSound = true
                }
            } else if verticalVelocity > 0 && positionY >= input.homeY {
                let targetRoll = Int32(
                    Float(numberOfTurns) / Float(input.numberOfSides) * 0x10000
                )
                let startRoll = Int32(faceRoll)
                faceRoll = approachSymmetric(
                    value: faceRoll,
                    target: Int16(truncatingIfNeeded: targetRoll),
                    increment: 0x4B0
                )
                angleVelocityRoll = Int16(truncatingIfNeeded: Int32(faceRoll) - startRoll)
                if angleVelocityRoll == 0 {
                    playedClickSound = true
                    numberOfTurns = (numberOfTurns + 1) % input.numberOfSides
                    timer = 0
                    if input.speedSetting == 2 {
                        rotationDelay = input.randomRotationDelay
                    }
                }
            } else {
                verticalVelocity += 0.5
                positionY += verticalVelocity
                if positionY >= input.homeY {
                    positionY = input.homeY
                    soundTimer = 6
                }
            }
        } else {
            verticalVelocity = -5
        }

        return SM64TTCRotatingSolidOutput(
            timer: timer,
            rotationDelay: rotationDelay,
            soundTimer: soundTimer,
            verticalVelocity: verticalVelocity,
            positionY: positionY,
            numberOfTurns: numberOfTurns,
            faceRoll: faceRoll,
            angleVelocityRoll: angleVelocityRoll,
            playedAlertSound: playedAlertSound,
            playedClickSound: playedClickSound
        )
    }

    private static func approachSymmetric(value: Int16, target: Int16, increment: Int16) -> Int16 {
        let distance = Int32(target) - Int32(value)
        if distance >= 0 {
            return distance > Int32(increment)
                ? Int16(truncatingIfNeeded: Int32(value) + Int32(increment))
                : target
        }
        return distance < -Int32(increment)
            ? Int16(truncatingIfNeeded: Int32(value) - Int32(increment))
            : target
    }
}
