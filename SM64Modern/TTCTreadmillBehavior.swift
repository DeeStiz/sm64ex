import Foundation

struct SM64TTCTreadmillInitialization: Equatable, Sendable {
    let collisionModelIndex: UInt8
    let initialSurfaceSpeed: Float
}

struct SM64TTCTreadmillInput: Equatable, Sendable {
    let speedSetting: Int32
    let timer: Int32
    let timeUntilSwitch: Int32
    let speed: Float
    let targetSpeed: Float
    let isMaster: Bool
    let noMasterExists: Bool
    let randomTimeUntilSwitch: Int32
    let randomDirection: Int32
}

struct SM64TTCTreadmillOutput: Equatable, Sendable {
    let speed: Float
    let targetSpeed: Float
    let timeUntilSwitch: Int32
    let timer: Int32
    let forwardVelocity: Float
    let becameMaster: Bool
    let playsElevatorSound: Bool
}

/// Value counterpart of `bhv_ttc_treadmill_init` and
/// `bhv_ttc_treadmill_update`.
enum SM64TTCTreadmillBehavior {
    private static let speeds: [Float] = [50, 100, 0, 0]

    static func initialize(behaviorByte: UInt8, speedSetting: Int32) -> SM64TTCTreadmillInitialization {
        SM64TTCTreadmillInitialization(
            collisionModelIndex: behaviorByte & 1,
            initialSurfaceSpeed: speeds[Int(speedSetting)]
        )
    }

    static func update(_ input: SM64TTCTreadmillInput) -> SM64TTCTreadmillOutput {
        var speed = input.speed
        var targetSpeed = input.targetSpeed
        var timeUntilSwitch = input.timeUntilSwitch
        var timer = input.timer
        var becameMaster = false
        var playsElevatorSound = false

        if input.isMaster || input.noMasterExists {
            becameMaster = !input.isMaster && input.noMasterExists
            playsElevatorSound = true
            if input.speedSetting == 2 {
                if input.timer > input.timeUntilSwitch {
                    if approach(&speed, target: 0, delta: 10) {
                        timeUntilSwitch = input.randomTimeUntilSwitch
                        targetSpeed = Float(input.randomDirection) * 50
                        timer = 0
                    }
                } else if input.timer > 5 {
                    _ = approach(&speed, target: targetSpeed, delta: 10)
                }
            }
        }

        return SM64TTCTreadmillOutput(
            speed: speed,
            targetSpeed: targetSpeed,
            timeUntilSwitch: timeUntilSwitch,
            timer: timer,
            forwardVelocity: 0.084 * speed,
            becameMaster: becameMaster,
            playsElevatorSound: playsElevatorSound
        )
    }

    @discardableResult
    private static func approach(_ value: inout Float, target: Float, delta: Float) -> Bool {
        var step = delta
        if value > target { step = -step }
        value += step
        if (value - target) * step >= 0 {
            value = target
            return true
        }
        return false
    }
}
