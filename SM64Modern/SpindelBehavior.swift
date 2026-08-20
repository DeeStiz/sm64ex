import Foundation

struct SM64SpindelInput: Equatable, Sendable {
    let timer: Int32
    let phase: Int32
    let direction: Int32
    let position: SM64ObjectVector3
    let homeY: Float
    let movePitch: Int32
}

struct SM64SpindelOutput: Equatable, Sendable {
    let timer: Int32
    let phase: Int32
    let direction: Int32
    let position: SM64ObjectVector3
    let movePitch: Int32
    let velocityZ: Float
    let angleVelocityPitch: Int32
    let playRollSound: Bool
    let cameraShake: Bool
}

/// Value counterpart of `bhv_spindel_init/loop`.
enum SM64SpindelBehavior {
    static func update(_ input: SM64SpindelInput) -> SM64SpindelOutput {
        var timer = input.timer &+ 1
        var phase = input.phase
        var direction = input.direction
        var position = input.position
        var pitch = input.movePitch
        var velocityZ: Float = 0
        var angleVelocity: Int32 = 0
        var playSound = false
        var shake = false
        if phase == -1 {
            if input.timer == 32 {
                phase = 0
                timer = 0
            } else {
                return .init(timer: timer, phase: phase, direction: direction, position: position, movePitch: pitch, velocityZ: 0, angleVelocityPitch: 0, playRollSound: false, cameraShake: false)
            }
        }
        var speed = 10 - phase
        if speed < 0 { speed = -speed }
        speed = max(speed - 6, 0)
        var moveTimer = input.timer
        if input.timer == speed + 8 {
            phase += 1
            timer = 0
            moveTimer = 0
            if phase == 20 {
                direction = direction == 0 ? 1 : 0
                phase = -1
            }
        }
        let divisor: Int32
        if speed == 4 || speed == 3 { divisor = 4 }
        else if speed == 2 || speed == 1 { divisor = 2 }
        else { divisor = 1 }
        if moveTimer < divisor * 8 {
            let sign: Float = direction == 0 ? 1 : -1
            velocityZ = sign * Float(20 / divisor)
            angleVelocity = (direction == 0 ? 1 : -1) * (1024 / divisor)
            position.z += velocityZ
            pitch &+= angleVelocity
            position.y = input.homeY + abs(SM64CanonicalTrig.sins(Int16(truncatingIfNeeded: pitch &* 4)) * 23)
            shake = moveTimer + 1 == divisor * 8
            let wrapped = pitch & 0x1FFF
            playSound = abs(wrapped) < 800 && angleVelocity != 0
        }
        return .init(timer: timer, phase: phase, direction: direction, position: position, movePitch: pitch, velocityZ: velocityZ, angleVelocityPitch: angleVelocity, playRollSound: playSound, cameraShake: shake)
    }
}
