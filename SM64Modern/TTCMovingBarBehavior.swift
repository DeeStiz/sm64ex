import Foundation

struct SM64TTCMovingBarInitialization: Equatable, Sendable {
    let delay: Int32
    let offset: Float
    let stoppedTimer: Int32
    let moveYaw: Int16
}

struct SM64TTCMovingBarInput: Equatable, Sendable {
    let speedSetting: Int32
    let action: Int32
    let timer: Int32
    let delay: Int32
    let stoppedTimer: Int32
    let offset: Float
    let speed: Float
    let faceYaw: Int16
    let randomDelay: Int32
    let randomPauseSelected: Bool
    let randomPauseTimer: Int32
    let randomFakeout: Bool
}

struct SM64TTCMovingBarOutput: Equatable, Sendable {
    let action: Int32
    let timer: Int32
    let delay: Int32
    let stoppedTimer: Int32
    let offset: Float
    let speed: Float
    let startOffset: Float
    let moveYaw: Int16
}

/// Value counterpart of `bhv_ttc_moving_bar_init` and
/// `bhv_ttc_moving_bar_update`.
enum SM64TTCMovingBarBehavior {
    private static let wait: Int32 = 0
    private static let pullBack: Int32 = 1
    private static let extend: Int32 = 2
    private static let retract: Int32 = 3
    private static let delays: [Int32] = [55, 30, 55, 0]

    static func initialize(speedSetting: Int32, behaviorByte: Int32, faceYaw: Int16)
        -> SM64TTCMovingBarInitialization
    {
        let delay = delays[Int(speedSetting)]
        return SM64TTCMovingBarInitialization(
            delay: delay,
            offset: delay == 0 ? 250 : 0,
            stoppedTimer: 10 * behaviorByte,
            moveYaw: Int16(truncatingIfNeeded: 0x4000 - Int32(faceYaw))
        )
    }

    static func update(_ input: SM64TTCMovingBarInput) -> SM64TTCMovingBarOutput {
        var action = input.action
        var delay = input.delay
        var stoppedTimer = input.stoppedTimer
        var offset = input.offset
        var speed = input.speed
        let startOffset = offset
        offset += speed

        switch input.action {
        case wait:
            if delay != 0 && input.timer > delay {
                if stoppedTimer != 0 {
                    stoppedTimer -= 1
                } else {
                    if input.speedSetting == 2 {
                        delay = input.randomDelay
                        if input.randomPauseSelected {
                            stoppedTimer = input.randomPauseTimer
                        }
                    }
                    action = pullBack
                    speed = -8
                }
            }
        case pullBack:
            speed += 0.73
            if speed > 0 {
                if stoppedTimer != 0 {
                    stoppedTimer -= 1
                    speed = 0
                } else {
                    action = extend
                    speed = 29
                }
            }
        case extend:
            if (offset == 250
                || (250 - offset) * (250 - startOffset) < 0)
                && speed > -8 && speed < 8
            {
                action = retract
                speed = 0
            } else {
                var acceleration: Float = offset < 250 ? 6.4 : -6.4
                if speed * acceleration < 0 {
                    acceleration *= 2.35
                }
                speed += acceleration
                if input.speedSetting == 2 && offset * startOffset < 0 && input.randomFakeout {
                    action = wait
                    offset = 0
                    speed = 0
                }
            }
        case retract:
            if input.timer > 30 {
                speed = -5
                if offset < 0 {
                    action = wait
                    offset = 0
                    speed = 0
                }
            }
        default:
            break
        }

        return SM64TTCMovingBarOutput(
            action: action,
            timer: input.timer,
            delay: delay,
            stoppedTimer: stoppedTimer,
            offset: offset,
            speed: speed,
            startOffset: startOffset,
            moveYaw: Int16(truncatingIfNeeded: 0x4000 - Int32(input.faceYaw))
        )
    }
}
