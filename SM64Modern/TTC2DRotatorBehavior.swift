import Foundation

struct SM64TTC2DRotatorInitialization: Equatable, Sendable {
    let minTimeUntilNextTurn: Int32
    let increment: Int16
    let speed: Int16
    let targetYaw: Int32
}

struct SM64TTC2DRotatorInput: Equatable, Sendable {
    let speedSetting: Int32
    let behaviorByte: Int32
    let timer: Int32
    let minTimeUntilNextTurn: Int32
    let targetYaw: Int32
    let increment: Int16
    let speed: Int16
    let randomDirectionTimer: Int32
    let faceYaw: Int16
    let randomUsesSpeed: Bool
    let randomSpeedTimer: Int32
    let randomReverseTimer: Int32
    let randomMinTime: Int32
}

struct SM64TTC2DRotatorOutput: Equatable, Sendable {
    let timer: Int32
    let minTimeUntilNextTurn: Int32
    let targetYaw: Int32
    let increment: Int16
    let randomDirectionTimer: Int32
    let faceYaw: Int16
    let angleVelocityYaw: Int16
}

/// Value counterpart of `bhv_ttc_2d_rotator_init/update`. Random draws are
/// explicit inputs so live replay can supply the exact C decisions.
enum SM64TTC2DRotatorBehavior {
    private static let speeds: [Int16] = [-0x444, -0xCCC]
    private static let turnTimes: [[Int32]] = [[40, 10, 10, 0], [20, 5, 5, 0]]

    static func initialize(
        behaviorByte: Int32,
        speedSetting: Int32,
        faceYaw: Int16
    ) -> SM64TTC2DRotatorInitialization {
        let kind = max(0, min(1, Int(behaviorByte)))
        let setting = max(0, min(3, Int(speedSetting)))
        let speed = speeds[kind]
        return SM64TTC2DRotatorInitialization(
            minTimeUntilNextTurn: turnTimes[kind][setting],
            increment: speed,
            speed: speed,
            targetYaw: Int32(faceYaw)
        )
    }

    static func update(_ input: SM64TTC2DRotatorInput) -> SM64TTC2DRotatorOutput {
        var timer = input.timer
        var minTime = input.minTimeUntilNextTurn
        var targetYaw = input.targetYaw
        var increment = input.increment
        var randomDirectionTimer = input.randomDirectionTimer
        let startYaw = input.faceYaw
        let faceYaw = approach(
            value: input.faceYaw,
            target: Int16(truncatingIfNeeded: targetYaw),
            increment: 0xC8
        ).value

        if randomDirectionTimer != 0 { randomDirectionTimer -= 1 }
        if minTime != 0 && approach(
            value: input.faceYaw,
            target: Int16(truncatingIfNeeded: targetYaw),
            increment: 0xC8
        ).reached && timer > minTime {
            targetYaw = targetYaw &+ Int32(increment)
            timer = 0
            if input.speedSetting == 2 {
                if randomDirectionTimer == 0 {
                    if input.randomUsesSpeed {
                        increment = input.speed
                        randomDirectionTimer = input.randomSpeedTimer
                    } else {
                        increment = Int16(truncatingIfNeeded: -Int32(input.speed))
                        randomDirectionTimer = input.randomReverseTimer
                    }
                }
                minTime = input.randomMinTime
            }
        }
        return SM64TTC2DRotatorOutput(
            timer: timer,
            minTimeUntilNextTurn: minTime,
            targetYaw: targetYaw,
            increment: increment,
            randomDirectionTimer: randomDirectionTimer,
            faceYaw: faceYaw,
            angleVelocityYaw: Int16(truncatingIfNeeded: Int32(faceYaw) - Int32(startYaw))
        )
    }

    private static func approach(value: Int16, target: Int16, increment: Int16)
        -> (value: Int16, reached: Bool)
    {
        let distance = Int16(truncatingIfNeeded: Int32(target) - Int32(value))
        if distance >= 0 {
            if distance > increment {
                return (Int16(truncatingIfNeeded: Int32(value) + Int32(increment)), false)
            }
        } else if distance < -increment {
            return (Int16(truncatingIfNeeded: Int32(value) - Int32(increment)), false)
        }
        return (target, true)
    }
}
