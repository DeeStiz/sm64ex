import Foundation

struct SM64TTCSpinnerInput: Equatable, Sendable {
    let speedSetting: Int32
    let timer: Int32
    let changeDirectionTimer: Int32
    let direction: Int32
    let facePitch: Int16
    let randomDirection: Int32
    let randomChangeDirectionTimer: Int32
}

struct SM64TTCSpinnerOutput: Equatable, Sendable {
    let angleVelocityPitch: Int16
    let direction: Int32
    let changeDirectionTimer: Int32
    let timer: Int32
    let facePitch: Int16
}

/// Value counterpart of `bhv_ttc_spinner_update`.
enum SM64TTCSpinnerBehavior {
    private static let speeds: [Int16] = [200, 600, 200, 0]

    static func update(_ input: SM64TTCSpinnerInput) -> SM64TTCSpinnerOutput {
        var angleVelocityPitch = speeds[Int(input.speedSetting)]
        var direction = input.direction
        var changeDirectionTimer = input.changeDirectionTimer
        var timer = input.timer

        if input.speedSetting == 2 {
            if input.timer > input.changeDirectionTimer {
                direction = input.randomDirection
                changeDirectionTimer = input.randomChangeDirectionTimer
                timer = 0
            } else if input.timer > 5 {
                angleVelocityPitch = Int16(truncatingIfNeeded: Int32(angleVelocityPitch) * direction)
            } else {
                angleVelocityPitch = 0
            }
        }

        let facePitch = Int16(
            bitPattern: UInt16(bitPattern: input.facePitch)
                &+ UInt16(bitPattern: angleVelocityPitch)
        )
        return SM64TTCSpinnerOutput(
            angleVelocityPitch: angleVelocityPitch,
            direction: direction,
            changeDirectionTimer: changeDirectionTimer,
            timer: timer,
            facePitch: facePitch
        )
    }
}
