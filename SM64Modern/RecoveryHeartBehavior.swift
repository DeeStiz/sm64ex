import Foundation

struct SM64RecoveryHeartInput: Equatable, Sendable {
    let collidedWithMario: Bool
    let marioForwardVelocity: Float
    let soundPlayed: Bool
    let yawVelocity: Int32
    let totalSpin: Int32
    let faceYaw: Int32
}
struct SM64RecoveryHeartOutput: Equatable, Sendable {
    let soundSpin: Bool
    let soundPlayed: Bool
    let yawVelocity: Int32
    let totalSpin: Int32
    let faceYaw: Int32
    let healCounterDelta: Int32
    let hitboxRadius: Float
    let hitboxHeight: Float
    let hurtboxRadius: Float
    let hurtboxHeight: Float
}
enum SM64RecoveryHeartBehavior {
    static func update(_ input: SM64RecoveryHeartInput) -> SM64RecoveryHeartOutput {
        var yawVelocity = input.yawVelocity
        var totalSpin = input.totalSpin
        var soundPlayed = input.soundPlayed
        var soundSpin = false
        if input.collidedWithMario {
            if !soundPlayed { soundSpin = true; soundPlayed = true }
            yawVelocity = Int32(200 * input.marioForwardVelocity) &+ 1000
        } else {
            soundPlayed = false
            yawVelocity &-= 50
            if yawVelocity < 400 { yawVelocity = 400; totalSpin = 0 }
        }
        totalSpin &+= yawVelocity
        var heal: Int32 = 0
        if totalSpin >= 0x10000 { heal = 4; totalSpin &-= 0x10000 }
        return .init(soundSpin: soundSpin, soundPlayed: soundPlayed, yawVelocity: yawVelocity, totalSpin: totalSpin, faceYaw: input.faceYaw &+ yawVelocity, healCounterDelta: heal, hitboxRadius: 50, hitboxHeight: 50, hurtboxRadius: 50, hurtboxHeight: 50)
    }
}
